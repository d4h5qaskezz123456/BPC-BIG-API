codeunit 80000 "BPC.Interface Data"
{
    Permissions = tabledata 110 = rim, tabledata "Purch. Rcpt. Header" = m;

    // // TestCallAPI                // For Test
    // // APITestConnection          // Test Connection
    // // Token                      // Log Token

    // // GetPurchaseHeader          // Retail Purchase Order Header
    // // GetPurchaseLine            // Retail Purchase Order Line
    // // GetSalesHeader             // Retail Sales Order Header  //TAR
    // // GetSalesLine               // Retail Sales Order Line  //TAR
    // // SendPurchaseReceive        // Send Purchase Receipt
    // // PostSalesShipment          // Post Shipment  //TAR
    // // SendUndoShipment           // Undo Shipment //TAR
    // // SendExpense                // Post PurchaseInvoice //TAR
    // // SendUndoReceipt            // Undo Receipt
    // // PostTransfersShipment      // Transfers Post Ship
    // // PostTransfersReceipt       // Transfers Post Receipt
    // // PostTransferJournal        // Post Transfer Journal
    // // PostItemJournal            // Post ItemJournal หน้า StoreInventoryWorksheet
    // // PostItemJournals           // Post ItemJournal หน้า ItemJournal
    // // postStmtJournal            //Post create journal in FO
    // // postStmtMovement           //Post issue stock in FO
    // // getGRNStatus               //Get GRN Status



    // // GetTransferHeader          // Retail Transfer Header
    // // GetTransferLine            // Retail Transfer Line
    // // PostPurchaseReceive        // Post Receive
    // // PostPurchaseShipment       // Post Ship  
    // // SendCheckSerial            // Check Serial (สินค้าคุม Serial)
    // // SendCheckStock             // Check Stock (สินค้าทั่วไป)
    // // CheckSerialExist           // Check stock ใน Inventory
    // // SendCloseBill              // ปิดบิล
    // // SendVoidBill               // Void บิล
    // // SendChkInvenLookupInStock  // Inventory Lookup เช็ค stock
    // // PostTransfersReceiptAuto   // Post Receive Auto  
    // // PostInventCountingJournal  // Post Invent Counting Journal
    // // PostInventAdjustJournal    // Post Invent Positive/Negative Journal
    // // CreateProduct              //Create item to FO
    // // getStmtStatus              //Get to Update Ledger Journal and Movement Journal
    // // getInventTrans             //Get movement from F&O

    trigger OnRun()
    var
        PostedStmt: Record "LSC Posted Statement";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        InterfaceDocumentStatus: Record "BPC.Interface Document Status";
        TmpDocStatus: Record "BPC.Interface Document Status" temporary;
    begin
        if GUIALLOWED then begin
            if NOT CONFIRM('Run Get Status?') then
                exit;
        end;

        GetInventTrans;
        PostedStmt.Reset();
        if PostedStmt.FindSet() then
            repeat
                if (PostedStmt."BPC.Journal ID" = '') OR (PostedStmt."BPC.Movement ID" = '') then
                    GetStmtStatus(PostedStmt);
            until PostedStmt.Next() = 0;

        TmpDocStatus.Reset();
        TmpDocStatus.DeleteAll();
        InterfaceDocumentStatus.Reset();
        InterfaceDocumentStatus.SetRange("BPC.Document Type", InterfaceDocumentStatus."BPC.Document Type"::GRN);
        InterfaceDocumentStatus.SetRange("BPC.Posted At FO", FALSE);
        if InterfaceDocumentStatus.FindSet() then
            repeat
                TmpDocStatus.Init();
                TmpDocStatus.TransferFields(InterfaceDocumentStatus);
                TmpDocStatus.Insert();
            until InterfaceDocumentStatus.Next() = 0;
        TmpDocStatus.Reset();
        if TmpDocStatus.FindSet() then
            repeat
                PurchRcptHeader.Get(TmpDocStatus."BPC.Document No.");
                GetGRNStatus(PurchRcptHeader, TRUE);
            until TmpDocStatus.Next() = 0;
        if GUIALLOWED then
            Message('Ok');
    end;

    var
        //FuncCenter: Codeunit "50007";
        ReleasePurchDoc: Codeunit "Release Purchase Document";
        ReleaseSaleshDoc: Codeunit "Release Sales Document";
        JSONMgt: Codeunit "JSON Management";
        JsonUtil: Codeunit "LSC POS JSON Util";
        JsonUtilBOM: Codeunit "LSC POS JSON Util";
        EposCtrl: Codeunit "LSC POS Control Interface";
        BOUtils: Codeunit "LSC BO Utils";
        // Convert: DotNet Convert;
        // Encoding: DotNet Encoding;
        // JArrayData: DotNet JArray;
        // dd: Codeunit DotNet_Array;
        TmpItemLedgerEntry: Record "Item Ledger Entry" temporary;
        JObjectData: JsonObject;
        JArrayData: JsonArray;
        JToken: JsonToken;
        Convert: Codeunit "Base64 Convert";
        // Encoding: DotNet Encoding;
        // JArrayData: JsonArray ;
        // JObjectData: JsonObject;
        GLSetup: Record "General Ledger Setup";
        RetailSetup: Record "LSC Retail Setup";
        APIConfiguration: Record "BPC.API Configuration";
        TempSalesHeader: Record "Sales Header" temporary;
        TempItem: Record Item temporary;
        TempSalesLine: Record "Sales Line" temporary;
        TempSalesLine1: Record "Sales Line" temporary;
        TempSalesLine2: Record "Sales Line" temporary;
        TempPurchHeader: Record "Purchase Header" temporary;
        TempPurchLine: Record "Purchase Line" temporary;
        TempTransfHeader: Record "Transfer Header" temporary;
        TempTransfLine: Record "Transfer Line" temporary;
        ReservEntry: Record "Reservation Entry";
        TempReservEntry: Record "Reservation Entry" temporary;
        StoreInventoryWorksheet: Record "LSC Store Inventory Worksheet";
        StoreInventoryLine: Record "LSC Store Inventory Line";
        PostedStoreInventoryLine: Record "BPC.Posted Store InventoryLine";
        Vend: Record Vendor;
        PurchSetup: Record "Purchases & Payables Setup";
        SaleshSetup: Record "Sales & Receivables Setup";
        Store: Record "LSC Store";
        TMPAssemblyLine: Record "Assembly Line" temporary;
        TMPAssemblyHeader: Record "Assembly Header" temporary;
        TMPAssembletoOrderLink: Record "Assemble-to-Order Link" temporary;
        ItemVariantRegistration: Record "LSC Item Variant Registration";
        RecRef: RecordRef;
        Window: Dialog;
        WindowUPDATE: Integer;
        JsonRequestStr: Text;
        APIResult: Text;
        Text000: Label 'Do you really want to undo the selected Receipt lines?\Receipt No. %1';
        ErrorMsg: Text;
        Text001: Label 'D365 Error Message : %1';
        FunctionsName: Text;
        DocumentNo: Text;
        Company_Name: Text;
        LastShipmentNo: Code[20];
        LastReceiptNo: Code[20];
        JnlDocID_g: Code[20];

        DocType: Option Shipment,Receipt;



    procedure CheckConfigInterface()
    begin
        RetailSetup.Get();
        if NOT RetailSetup."BPC.Interface D365 Active" then
            ERROR('Interface D365 Active for Retail Setup not Active');
        if RetailSetup."BPC.Interface Tenant ID" = '' then begin
            if RetailSetup."BPC.Interface User Name" = '' then
                ERROR('Interface User Name for Retail Setup not found');
            if RetailSetup."BPC.Interface Password" = '' then
                ERROR('Interface Password for Retail Setup not found');
        end;
        if RetailSetup."BPC.Interface ClientID" = '' then
            ERROR('Interface ClientID for Retail Setup not found');
        if RetailSetup."BPC.Interface Client Secret" = '' then
            ERROR('Interface Client Secret for Retail Setup not found');
        if RetailSetup."BPC.Interface Resource" = '' then
            ERROR('Interface Resource for Retail Setup not found');
        if RetailSetup."BPC.Interface Company" = '' then
            ERROR('Interface Company for Retail Setup not found');

        Company_Name := RetailSetup."BPC.Interface Company";
    end;

    procedure CheckConfigInterface2()
    begin
        RetailSetup.Get();
        // if NOT RetailSetup."BPC.Interface D365 Active" then
        //     ERROR('Interface D365 Active for Retail Setup not Active');
        if RetailSetup."BPC.Interface Tenant ID" = '' then begin
            if RetailSetup."BPC.Interface User Name" = '' then
                ERROR('Interface User Name for Retail Setup not found');
            if RetailSetup."BPC.Interface Password" = '' then
                ERROR('Interface Password for Retail Setup not found');
        end;
        if RetailSetup."BPC.Interface ClientID" = '' then
            ERROR('Interface ClientID for Retail Setup not found');
        if RetailSetup."BPC.Interface Client Secret" = '' then
            ERROR('Interface Client Secret for Retail Setup not found');
        if RetailSetup."BPC.Interface Resource" = '' then
            ERROR('Interface Resource for Retail Setup not found');
        if RetailSetup."BPC.Interface Company" = '' then
            ERROR('Interface Company for Retail Setup not found');

        Company_Name := RetailSetup."BPC.Interface Company";
    end;


    procedure APITestConnection(): Text
    begin
        Clear(JsonRequestStr);
        Clear(APIResult);
        CheckConfigInterface();

        FunctionsName := 'APITestConnection';
        DocumentNo := '';
        if NOT CallAPIService_POST(FunctionsName, JsonRequestStr, APIResult, DocumentNo) then
            APIResult := '';
        EXIT(APIResult);
    end;

    local procedure "------------Get Data------------"()
    begin
    end;


    procedure GetSalesHeader()
    var
        RetailUser: Record "LSC Retail User";
        StoreLocation: Record "LSC Store Location";
        SalesHeader: Record "Sales Header";
    begin
        Clear(JsonRequestStr);
        Clear(APIResult);
        CheckConfigInterface();

        if RetailUser.Get(USERID) then begin
            StoreLocation.Reset();
            StoreLocation.SetRange("Store No.", RetailUser."Store No.");
            if StoreLocation.FindSet() then begin
                repeat
                    if StoreLocation."Location Code" <> '' then begin // วนขอข้อมูลแต่ละ Location
                        FunctionsName := 'GetSalesHeader';
                        DocumentNo := '';
                        JsonRequestStr := StrSubstNo('{company:"%1",warehouse:"%2"}', Company_Name, StoreLocation."Location Code");
                        if CallAPIService_POST(FunctionsName, JsonRequestStr, APIResult, DocumentNo) then begin
                            GenerateTempSalesOrder(TRUE, APIResult, SalesHeader);
                            InsertSalesOrder(TRUE, RetailUser."Store No.", StoreLocation."Location Code", SalesHeader);
                        end;
                    end;
                until StoreLocation.Next() = 0;
            end;
        end;
    end;

    procedure GetSalesLine(var SalesHeader: Record "Sales Header")
    var
    begin
        Clear(JsonRequestStr);
        Clear(APIResult);
        CheckConfigInterface();

        FunctionsName := 'GetSalesLine';
        DocumentNo := SalesHeader."No.";
        JsonRequestStr := StrSubstNo('{company:"%1",warehouse:"%2",salesOrder:"%3"}', Company_Name, SalesHeader."Location Code", SalesHeader."No.");
        if CallAPIService_POST(FunctionsName, JsonRequestStr, APIResult, DocumentNo) then begin
            GenerateTempSalesOrder(FALSE, APIResult, SalesHeader);
            if NOT CheckExistPostedPending(SalesHeader."No.") then begin
                ReleaseSaleshDoc.PerformManualReopen(SalesHeader);
                InsertSalesOrder(FALSE, SalesHeader."LSC Store No.", SalesHeader."Location Code", SalesHeader);
                ReleaseSaleshDoc.PerformManualRelease(SalesHeader);
            end;
        end else
            Message('%1', GetLastErrorText());
    end;

    procedure GetPurchaseHeader()
    var
        RetailUser: Record "LSC Retail User";
        StoreLocation: Record "LSC Store Location";
        PurchHeader: Record "Purchase Header";
    begin
        Clear(JsonRequestStr);
        Clear(APIResult);
        CheckConfigInterface();

        if RetailUser.Get(USERID) then begin
            StoreLocation.RESET();
            StoreLocation.SetRange("Store No.", RetailUser."Store No.");
            if StoreLocation.FINDSET() then
                repeat
                    if StoreLocation."Location Code" <> '' then begin // วนขอข้อมูลแต่ละ Location
                        FunctionsName := 'GetPurchaseHeader';
                        DocumentNo := '';
                        JsonRequestStr := StrSubstNo('{company:"%1",warehouse:"%2"}', Company_Name, StoreLocation."Location Code");
                        if CallAPIService_POST(FunctionsName, JsonRequestStr, APIResult, DocumentNo) then begin
                            GenerateTempPurchOrder(TRUE, APIResult, PurchHeader);
                            InsertPurchOrder(TRUE, RetailUser."Store No.", StoreLocation."Location Code");
                        end;
                    end;
                until StoreLocation.NEXT() = 0;
        end;
    end;

    procedure GetPurchaseLine(var PurchHeader: Record "Purchase Header")
    var
        InterfaceDocumentStatus: Record "BPC.Interface Document Status";
    begin
        Clear(JsonRequestStr);
        Clear(APIResult);
        CheckConfigInterface();

        FunctionsName := 'GetPurchaseLine';
        DocumentNo := PurchHeader."No.";
        JsonRequestStr := StrSubstNo('{company:"%1",warehouse:"%2",purchaseOrder:"%3"}', Company_Name, PurchHeader."Location Code", PurchHeader."No.");
        if CallAPIService_POST(FunctionsName, JsonRequestStr, APIResult, DocumentNo) then begin
            GenerateTempPurchOrder(FALSE, APIResult, PurchHeader);
            if NOT CheckExistPostedPending(PurchHeader."No.") then begin
                ReleasePurchDoc.PerformManualReopen(PurchHeader);
                InsertPurchOrder(FALSE, PurchHeader."LSC Store No.", PurchHeader."Location Code");
                PurchHeader.Status := PurchHeader.Status::Released;
                PurchHeader.Modify();
                // ReleasePurchDoc.PerformManualRelease(PurchHeader);
            end else begin
                InterfaceDocumentStatus.Reset();
                InterfaceDocumentStatus.SetRange("BPC.Document Type", InterfaceDocumentStatus."BPC.Document Type"::GRN);
                InterfaceDocumentStatus.SetRange("BPC.Reference Document No.", PurchHeader."No.");
                if InterfaceDocumentStatus.FindFirst() then//Oat fix
                    ERROR('Purchase Order %1 have pending Posted Document\GRN No.: %2', PurchHeader."No.", InterfaceDocumentStatus."BPC.Document No.");
            end;
        end else
            Message('%1', GetLastErrorText());
    end;

    procedure CheckExistPostedPending(pPurchOrderNo: Code[20]): Boolean
    var
        InterfaceDocumentStatus: Record "BPC.Interface Document Status";
    begin
        if pPurchOrderNo = '' then
            EXIT(TRUE);

        InterfaceDocumentStatus.Reset();
        InterfaceDocumentStatus.SetRange("BPC.Document Type", InterfaceDocumentStatus."BPC.Document Type"::GRN);
        InterfaceDocumentStatus.SetRange("BPC.Reference Document No.", pPurchOrderNo);
        InterfaceDocumentStatus.SetRange("BPC.Posted At FO", FALSE);
        EXIT(InterfaceDocumentStatus.FindFirst());
    end;

    procedure GetTransferHeader()
    var
        RetailUser: Record "LSC Retail User";
        StoreLocation: Record "LSC Store Location";
        TransfHeader: Record "Transfer Header";
    begin
        Clear(JsonRequestStr);
        Clear(APIResult);
        CheckConfigInterface();

        if RetailUser.Get(USERID) then begin
            StoreLocation.Reset();
            StoreLocation.SetRange("Store No.", RetailUser."Store No.");
            if StoreLocation.FindSet() then begin
                repeat
                    if StoreLocation."Location Code" <> '' then begin
                        // วนขอข้อมูลแต่ละ Location
                        FunctionsName := 'GetTransferHeader';
                        DocumentNo := '';
                        JsonRequestStr := StrSubstNo('{company:"%1",warehouse:"%2"}', Company_Name, StoreLocation."Location Code");
                        if CallAPIService_POST(FunctionsName, JsonRequestStr, APIResult, DocumentNo) then begin
                            GenerateTempTransfOrder(TRUE, APIResult, TransfHeader);
                            InsertTransfOrder(TRUE, RetailUser."Store No.");
                        end;
                    end;
                until StoreLocation.Next() = 0;
            end;
        end;
    end;

    procedure GetTransferLine(var TransfHeader: Record "Transfer Header")
    begin
        Clear(JsonRequestStr);
        Clear(APIResult);
        CheckConfigInterface();

        FunctionsName := 'GetTransferLine';
        DocumentNo := TransfHeader."No.";
        JsonRequestStr := StrSubstNo('{company:"%1",warehouse:"%2",transferNo:"%3"}', Company_Name, TransfHeader."Transfer-from Code", TransfHeader."No.");
        if CallAPIService_POST(FunctionsName, JsonRequestStr, APIResult, DocumentNo) then begin
            GenerateTempTransfOrder(FALSE, APIResult, TransfHeader);
            InsertTransfOrder(FALSE, '');
        end else
            Message('%1', GetLastErrorText());
    end;

    local procedure "------------Post Data------------"()
    begin
    end;

    procedure PostPurchaseShipment(var Rec: Record "Purchase Header"; var FORcptNo: Code[50]): Boolean
    var
        PurchPost: Codeunit "Purch.-Post";
        PurchPyyost: Codeunit "TransferOrder-Post (Yes/No)";
        PurchaseHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        Item: Record Item;
        ReservationEntry: Record "Reservation Entry";
        APIResult: Text;
        JsonRequestStr: Text;
        llStatus: Boolean;
        lcPONo: Text;
        lcGRNNo: Text;
        ItemSerialCount: Integer;
        ExistItemNo: Text;
        ExistVariant: Text;
        ExistVariantName: Text;
        GenPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        InvPostingSetup: Record "Inventory Posting Setup";
    begin
        Clear(JsonRequestStr);
        Clear(APIResult);
        Clear(RecRef);
        Clear(ErrorMsg);
        CheckConfigInterface();

        // Check Item คุม Serial ++
        Rec.TESTFIELD("Posting Date");

        Clear(ItemSerialCount);
        PurchLine.Reset();
        PurchLine.SetRange("Document Type", Rec."Document Type");
        PurchLine.SetRange("Document No.", Rec."No.");
        PurchLine.SetRange(Type, PurchLine.Type::Item);
        PurchLine.SETFILTER("No.", '<>%1', '');
        if PurchLine.FindSet() then
            repeat
                PurchLine.TESTFIELD("Gen. Bus. Posting Group");
                PurchLine.TESTFIELD("Gen. Prod. Posting Group");
                GenPostingSetup.Get(PurchLine."Gen. Bus. Posting Group", PurchLine."Gen. Prod. Posting Group");
                VATPostingSetup.Get(PurchLine."VAT Bus. Posting Group", PurchLine."VAT Prod. Posting Group");

                if NOT Item.Get(PurchLine."No.") then
                    Item.Init();
                Item.TESTFIELD("Inventory Posting Group");
                InvPostingSetup.Get(PurchLine."Location Code", Item."Inventory Posting Group");

                if (Item."Item Tracking Code" in ['SERIAL', 'LOT']) AND (PurchLine."Qty. to Receive" <> 0) then begin
                    ReservationEntry.Reset();
                    ReservationEntry.SetRange("Source ID", PurchLine."Document No.");
                    ReservationEntry.SetRange("Item No.", PurchLine."No.");
                    ReservationEntry.SetRange("Location Code", PurchLine."Location Code");
                    ReservationEntry.SetRange("Source Type", DATABASE::"Purchase Line");
                    ReservationEntry.SetRange("Source Ref. No.", PurchLine."Line No.");
                    if Item."Item Tracking Code" = 'SERIAL' then begin
                        ReservationEntry.SETFILTER("Serial No.", '<>%1', '');
                        ItemSerialCount := ReservationEntry.COUNT;
                        if ItemSerialCount <> PurchLine."Return Qty. to Ship" then
                            ERROR('Item Line No. %1, Serial No. Not Equal To Qty. to Return Shipment', PurchLine."Line No.");
                        if ReservationEntry.FindSet() then
                            repeat
                                //CheckSerialExist
                                if SendCheckSerialInStock(ReservationEntry."Serial No.", ExistItemNo, ExistVariant, ExistVariantName) then begin
                                    ERROR('Serial: %1 already in stock.\Item No.: %2\Variant: %3 [%4]', ReservationEntry."Serial No.", ExistItemNo, ExistVariant, ExistVariantName);
                                end;
                            until ReservationEntry.Next() = 0;
                    end;
                    if Item."Item Tracking Code" = 'LOT' then begin
                        ReservationEntry.SETFILTER("Lot No.", '<>%1', '');
                        if ReservationEntry.ISEMPTY then begin
                            ERROR('Item No.: %2\Item Line No. %1, Lot No. Not found for Qty. to Return Shipment', PurchLine."Line No.", PurchLine."No.");
                        end;
                    end;
                end;
            until PurchLine.Next() = 0;
        // Check Item คุม Serial --

        RecRef.GetTable(Rec);
        FunctionsName := 'PostPurchaseShipment';
        DocumentNo := Rec."No.";
        JsonRequestStr := Convert.ToBase64(CreateJsonRequestStr(FunctionsName, RecRef));
        JsonRequestStr := StrSubstNo('{company:"%1",warehouse:"%2",PoReturnShipment:"%3"}', Company_Name, Rec."Location Code", JsonRequestStr);
        if CallAPIService_POST(FunctionsName, JsonRequestStr, APIResult, DocumentNo) then begin
            Clear(JSONMgt);
            // JSONMgt.InitializeCollection(APIResult);
            // JSONMgt.GetJsonArray(JArrayData);
            JArrayData.ReadFrom(APIResult);
            foreach JToken in JArrayData do begin
                JObjectData := JToken.AsObject();
                if JObjectData.Get('Status', JToken) then
                    llStatus := JToken.AsValue().AsBoolean();
                if JObjectData.Get('PONo', JToken) then
                    lcPONo := JToken.AsValue().AsText();
                if JObjectData.Get('GRNNo', JToken) then
                    lcGRNNo := JToken.AsValue().AsText();
                if JObjectData.Get('Message', JToken) then
                    ErrorMsg := JToken.AsValue().AsText();
                if (not llStatus) OR (lcGRNNo = '') then begin
                    if ErrorMsg <> '' then
                        Message(Text001, ErrorMsg)
                    else
                        Message('Can Not Post Return Shipment.\API: %1', APIResult);
                    EXIT(FALSE);
                end;

                FORcptNo := lcGRNNo;
                PurchaseHeader.Reset();
                PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
                PurchaseHeader.SETFILTER("No.", '%1', lcPONo);
                if PurchaseHeader.FINDFIRST then begin
                    PurchSetup.Get();
                    PurchaseHeader.Ship := true;
                    PurchaseHeader."Return Shipment No." := lcGRNNo;
                    PurchaseHeader."Return Shipment No. Series" := PurchSetup."Posted Return Shpt. Nos.";
                    OnBeforeRunPurchPost(PurchaseHeader);
                    PurchPost.RUN(PurchaseHeader);
                    Message('PO No. %1 has been Return Shipment.', lcPONo);
                    EXIT(TRUE); //Success
                end;
            end;
        end else begin
            Message('%1', GetLastErrorText());
            EXIT(FALSE);
        end;
    end;

    procedure PostPurchaseReceive(var Rec: Record "Purchase Header"; var FORcptNo: Code[50]): Boolean
    var
        PurchPost: Codeunit "Purch.-Post";
        PurchPyyost: Codeunit "TransferOrder-Post (Yes/No)";
        PurchaseHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        Item: Record Item;
        ReservationEntry: Record "Reservation Entry";
        APIResult: Text;
        JsonRequestStr: Text;
        llStatus: Boolean;
        lcPONo: Text;
        lcGRNNo: Text;
        ItemSerialCount: Integer;
        ExistItemNo: Text;
        ExistVariant: Text;
        ExistVariantName: Text;
        GenPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        InvPostingSetup: Record "Inventory Posting Setup";
    begin
        Clear(JsonRequestStr);
        Clear(APIResult);
        Clear(RecRef);
        Clear(ErrorMsg);
        CheckConfigInterface();

        // Check Item คุม Serial ++
        Rec.TESTFIELD("Posting Date");

        Clear(ItemSerialCount);
        PurchLine.Reset();
        PurchLine.SetRange("Document Type", Rec."Document Type");
        PurchLine.SetRange("Document No.", Rec."No.");
        PurchLine.SetRange(Type, PurchLine.Type::Item);
        PurchLine.SETFILTER("No.", '<>%1', '');
        if PurchLine.FindSet() then
            repeat
                PurchLine.TESTFIELD("Gen. Bus. Posting Group");
                PurchLine.TESTFIELD("Gen. Prod. Posting Group");
                GenPostingSetup.Get(PurchLine."Gen. Bus. Posting Group", PurchLine."Gen. Prod. Posting Group");
                VATPostingSetup.Get(PurchLine."VAT Bus. Posting Group", PurchLine."VAT Prod. Posting Group");

                if NOT Item.Get(PurchLine."No.") then
                    Item.Init();
                Item.TESTFIELD("Inventory Posting Group");
                InvPostingSetup.Get(PurchLine."Location Code", Item."Inventory Posting Group");

                if (Item."Item Tracking Code" in ['SERIAL', 'LOT']) AND (PurchLine."Qty. to Receive" <> 0) then begin
                    ReservationEntry.Reset();
                    ReservationEntry.SetRange("Source ID", PurchLine."Document No.");
                    ReservationEntry.SetRange("Item No.", PurchLine."No.");
                    ReservationEntry.SetRange("Location Code", PurchLine."Location Code");
                    ReservationEntry.SetRange("Source Type", DATABASE::"Purchase Line");
                    ReservationEntry.SetRange("Source Ref. No.", PurchLine."Line No.");
                    if Item."Item Tracking Code" = 'SERIAL' then begin
                        ReservationEntry.SETFILTER("Serial No.", '<>%1', '');
                        ItemSerialCount := ReservationEntry.COUNT;
                        if ItemSerialCount <> PurchLine."Qty. to Receive" then
                            ERROR('Item Line No. %1, Serial No. Not Equal To Qty. to Receive', PurchLine."Line No.");
                        if ReservationEntry.FindSet() then
                            repeat
                                //CheckSerialExist
                                if SendCheckSerialInStock(ReservationEntry."Serial No.", ExistItemNo, ExistVariant, ExistVariantName) then begin
                                    ERROR('Serial: %1 already in stock.\Item No.: %2\Variant: %3 [%4]', ReservationEntry."Serial No.", ExistItemNo, ExistVariant, ExistVariantName);
                                end;
                            until ReservationEntry.Next() = 0;
                    end;
                    if Item."Item Tracking Code" = 'LOT' then begin
                        ReservationEntry.SETFILTER("Lot No.", '<>%1', '');
                        if ReservationEntry.ISEMPTY then begin
                            ERROR('Item No.: %2\Item Line No. %1, Lot No. Not found for Qty. to Receive', PurchLine."Line No.", PurchLine."No.");
                        end;
                    end;
                end;
            until PurchLine.Next() = 0;
        // Check Item คุม Serial --

        RecRef.GetTable(Rec);
        FunctionsName := 'PostPurchaseReceive';
        DocumentNo := Rec."No.";
        JsonRequestStr := Convert.ToBase64(CreateJsonRequestStr(FunctionsName, RecRef));
        JsonRequestStr := StrSubstNo('{company:"%1",warehouse:"%2",PoReceipt:"%3"}', Company_Name, Rec."Location Code", JsonRequestStr);
        if CallAPIService_POST(FunctionsName, JsonRequestStr, APIResult, DocumentNo) then begin
            Clear(JSONMgt);
            JArrayData.ReadFrom(APIResult);
            foreach JToken in JArrayData do begin
                JObjectData := JToken.AsObject();
                if JObjectData.Get('Status', JToken) then
                    llStatus := JToken.AsValue().AsBoolean();
                if JObjectData.Get('PONo', JToken) then
                    lcPONo := JToken.AsValue().AsText();
                if JObjectData.Get('GRNNo', JToken) then
                    lcGRNNo := JToken.AsValue().AsText();
                if JObjectData.Get('Message', JToken) then
                    ErrorMsg := JToken.AsValue().AsText();

                if (not llStatus) OR (lcGRNNo = '') then begin
                    if ErrorMsg <> '' then
                        Message(Text001, ErrorMsg)
                    else
                        Message('Can Not Post Receipt.\API: %1', APIResult);
                    EXIT(FALSE);
                end;

                FORcptNo := lcGRNNo;
                PurchaseHeader.Reset();
                PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
                PurchaseHeader.SETFILTER("No.", '%1', lcPONo);
                if PurchaseHeader.FINDFIRST then begin
                    PurchSetup.Get();
                    PurchaseHeader.Receive := true;
                    PurchaseHeader."Receiving No." := lcGRNNo;
                    PurchaseHeader."Receiving No. Series" := PurchSetup."Posted Receipt Nos.";
                    OnBeforeRunPurchPost(PurchaseHeader);
                    PurchPost.RUN(PurchaseHeader);
                    Message('PO No. %1 has been received.', lcPONo);
                    EXIT(TRUE); //Success
                end;
            end;
        end else begin
            Message('%1', GetLastErrorText());
            EXIT(FALSE);
        end;
    end;



    procedure SendPurchaseReceive(var Rec: Record "Purchase Header"; var LsRcptNo: Code[20]): Boolean
    var
        PurchPost: Codeunit "Purch.-Post";
        PurchaseHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        Item: Record Item;
        ReservationEntry: Record "Reservation Entry";
        APIResult: Text;
        JsonRequestStr: Text;
        llStatus: Boolean;
        lcPONo: Text;
        lcGRNNo: Text;
        ItemSerialCount: Integer;
        ExistItemNo: Text;
        ExistVariant: Text;
        ExistVariantName: Text;
        GenPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        InvPostingSetup: Record "Inventory Posting Setup";
        InterfaceDocumentStatus: Record "BPC.Interface Document Status";
    begin
        Clear(JsonRequestStr);
        Clear(APIResult);
        Clear(RecRef);
        Clear(ErrorMsg);
        CheckConfigInterface();

        PurchRcptHeader.Get(LsRcptNo);
        RecRef.GetTable(PurchRcptHeader);

        //DRPH
        if NOT InterfaceDocumentStatus.Get(InterfaceDocumentStatus."BPC.Document Type"::GRN, LsRcptNo) then begin
            InterfaceDocumentStatus.Init();
            InterfaceDocumentStatus."BPC.Document Type" := InterfaceDocumentStatus."BPC.Document Type"::GRN;
            InterfaceDocumentStatus."BPC.Document No." := LsRcptNo;
            InterfaceDocumentStatus.Insert();
        end;
        InterfaceDocumentStatus."BPC.Interface Date-Time" := CURRENTDATETIME;
        InterfaceDocumentStatus."BPC.Posted At FO" := FALSE;
        InterfaceDocumentStatus."BPC.Reference Document No." := PurchRcptHeader."Order No.";
        InterfaceDocumentStatus.MODIFY;
        //DRPH

        FunctionsName := 'SendPurchaseReceive';
        DocumentNo := PurchRcptHeader."Order No.";
        JsonRequestStr := Convert.ToBase64(CreateJsonRequestStr(FunctionsName, RecRef));
        JsonRequestStr := StrSubstNo('{company:"%1",warehouse:"%2",PoReceipt:"%3"}', Company_Name, Rec."Location Code", JsonRequestStr);
        if CallAPIService_POST(FunctionsName, JsonRequestStr, APIResult, DocumentNo) then begin
            Clear(JSONMgt);
            JArrayData.ReadFrom(APIResult);
            foreach JToken in JArrayData do begin
                JObjectData := JToken.AsObject();
                if JObjectData.Get('Status', JToken) then
                    llStatus := JToken.AsValue().AsBoolean();
                if JObjectData.Get('PONo', JToken) then
                    lcPONo := JToken.AsValue().AsText();
                if JObjectData.Get('GRNNo', JToken) then
                    lcGRNNo := JToken.AsValue().AsText();
                if JObjectData.Get('Message', JToken) then
                    ErrorMsg := JToken.AsValue().AsText();
                if (not llStatus) OR (lcGRNNo = '') then begin
                    if ErrorMsg <> '' then
                        Message(Text001, ErrorMsg)
                    else
                        Message('Send GRN to FO.\API: %1', APIResult);
                    EXIT(FALSE);
                end;

                //Kim 2025-05 ++
                PurchRcptHeader."BPC.To D365" := true;
                PurchRcptHeader.Modify();
                //Kim 2025-05 --

                Message('PO No. %1 has been Receive.', lcPONo);
                EXIT(TRUE);
            end;
        end else begin
            Message('%1', GetLastErrorText());
            EXIT(FALSE);
        end;
    end;

    procedure PostSalesShipment(var Rec: Record "Sales Header"; HideDialog: Boolean; ErrText: Text): Boolean
    var
        SalesHeader: Record "Sales Header";
        llStatus: Boolean;
        lcOrderNo: Text;
        lcShipNO: Text;
        SuppressCommit: Boolean;
        InvoicePDF: Text[10000000];
        Base64Conver: Codeunit "Base64 Convert";
        InStream: InStream;
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        SalesShipmentHeader: Record "Sales Shipment Header";
        NamePDF: Text;
        Nametxt: Text;
    begin
        Clear(JsonRequestStr);
        Clear(APIResult);
        Clear(RecRef);
        Clear(ErrorMsg);
        CheckConfigInterface();
        RecRef.GetTable(Rec);
        FunctionsName := 'PostSalesShipment';
        DocumentNo := Rec."No.";
        JsonRequestStr := Convert.ToBase64(CreateJsonRequestStr(FunctionsName, RecRef));
        JsonRequestStr := StrSubstNo('{company:"%1",warehouse:"%2",data:"%3"}', Company_Name, Rec."Location Code", JsonRequestStr);
        if CallAPIService_POST(FunctionsName, JsonRequestStr, APIResult, DocumentNo) then begin
            Clear(JSONMgt);
            JArrayData.ReadFrom(APIResult);
            foreach JToken in JArrayData do begin
                JObjectData := JToken.AsObject();
                if JObjectData.Get('Status', JToken) then
                    llStatus := JToken.AsValue().AsBoolean();
                if JObjectData.Get('SOH_SONo', JToken) then
                    lcOrderNo := JToken.AsValue().AsText();
                if JObjectData.Get('SOH_CustShipNo', JToken) then
                    lcShipNO := JToken.AsValue().AsText();
                if JObjectData.Get('Message', JToken) then
                    ErrorMsg := JToken.AsValue().AsText();
                if JObjectData.Get('SOH_InvoicePDF', JToken) then begin
                    if JToken.AsValue().IsNull() then
                        Message('No PDF file information')
                    else
                        InvoicePDF := JToken.AsValue().AsText();
                end;

                if NOT llStatus then begin
                    if InvoicePDF <> '' then begin
                        SalesShipmentHeader.Reset();
                        SalesShipmentHeader.SetRange("Order No.", lcOrderNo);
                        if SalesShipmentHeader.FindSet() then begin
                            TempBlob.CreateOutStream(OutStream);
                            Base64Conver.FromBase64(InvoicePDF, OutStream);
                            TempBlob.CreateInStream(InStream);
                            NamePDF := StrSubstNo('%1.pdf', lcOrderNo);
                            //Nametxt := StrSubstNo('%1.txt', lcOrderNo);
                            //DownloadFromStream(InStream, 'Download', '', '*.txt', Nametxt);
                            SalesShipmentHeader."BPC.File PDF".IMPORTSTREAM(InStream, NamePDF, 'application/pdf');
                            SalesShipmentHeader.Modify();
                            DownloadFromStream(InStream, 'Download', '', '*.pdf', NamePDF);

                        end;
                    end;

                    if ErrorMsg <> '' then
                        Message(Text001, ErrorMsg)
                    else
                        Message('Can Not Post Ship.');

                    exit;
                end;

                if InvoicePDF <> '' then begin
                    SalesShipmentHeader.Reset();
                    SalesShipmentHeader.SetRange("Order No.", lcOrderNo);
                    if SalesShipmentHeader.FindSet() then begin
                        TempBlob.CreateOutStream(OutStream);
                        Base64Conver.FromBase64(InvoicePDF, OutStream);
                        TempBlob.CreateInStream(InStream);
                        NamePDF := StrSubstNo('%1.pdf', lcOrderNo);
                        //Nametxt := StrSubstNo('%1.txt', lcOrderNo);
                        //DownloadFromStream(InStream, 'Download', '', '*.txt', Nametxt);
                        SalesShipmentHeader."BPC.File PDF".IMPORTSTREAM(InStream, NamePDF, 'application/pdf');
                        SalesShipmentHeader.Modify();
                        DownloadFromStream(InStream, 'Download', '', '*.pdf', NamePDF);

                    end;
                end;

                Message('SO No. %1 has been Shipping.', lcOrderNo);
                EXIT(TRUE); //Success
                // end;
            end;
        end else begin
            if NOT HideDialog then
                Message('%1', GetLastErrorText());
        end;
    end;

    procedure SendUndoShipment(Rec: Record "Sales Shipment Line")
    var
        JObjectData: JsonObject;
        JArrayData: JsonArray;
        JToken: JsonToken;
        InterfaceData: Codeunit "BPC.Interface Data";
        JsonRequestStr: Text;
        FunctionsName: text;
        DocumentNo: Text;
        APIResult: Text;
        ErrorMsg: text;
        llStatus: Boolean;
        Company_Name: Text;
        RetailSetup: Record "LSC Retail Setup";
    begin
        Clear(JsonRequestStr);
        Clear(APIResult);
        Clear(ErrorMsg);
        CheckConfigInterface();
        RetailSetup.Get();
        Company_Name := RetailSetup."BPC.Interface Company";
        FunctionsName := 'SendUndoShipment';
        DocumentNo := Rec."Document No.";
        GetDocInsLog(DocumentNo, FunctionsName);
        JsonRequestStr := StrSubstNo('{company:"%1",warehouse:"%2",sono:"%3",grnno:"%4"}', Company_Name, Rec."Location Code", Rec."Order No.", Rec."Document No.");
        if CallAPIService_POST(FunctionsName, JsonRequestStr, APIResult, DocumentNo) then begin
            JArrayData.ReadFrom(APIResult);
            foreach JToken in JArrayData do begin
                JObjectData := JToken.AsObject();
                if JObjectData.Get('Status', JToken) then
                    llStatus := JToken.AsValue().AsBoolean();
                if JObjectData.Get('Message', JToken) then
                    ErrorMsg := JToken.AsValue().AsText();
                if NOT llStatus then begin
                    if ErrorMsg <> '' then
                        ERROR(ErrorMsg)
                    else
                        ERROR('Can Not Undo Shipment.\API Data: %1', APIResult);
                    exit;
                end;
            end;
        end else
            ERROR('%1', GETLASTERRORTEXT);
    end;

    procedure SendUndoReceipt(Rec: Record "Purch. Rcpt. Line")
    var
        JObjectData: JsonObject;
        JArrayData: JsonArray;
        JToken: JsonToken;
        InterfaceData: Codeunit "BPC.Interface Data";
        JsonRequestStr: Text;
        FunctionsName: text;
        DocumentNo: Text;
        APIResult: Text;
        ErrorMsg: text;
        llStatus: Boolean;
        Company_Name: Text;
        RetailSetup: Record "LSC Retail Setup";
        InterfaceDocumentStatus: Record "BPC.Interface Document Status";
    begin
        Clear(JsonRequestStr);
        Clear(APIResult);
        Clear(ErrorMsg);
        CheckConfigInterface();
        RetailSetup.Get();
        Company_Name := RetailSetup."BPC.Interface Company";
        FunctionsName := 'SendUndoReceipt';
        DocumentNo := Rec."Document No.";
        GetDocInsLog(DocumentNo, FunctionsName);
        JsonRequestStr := StrSubstNo('{company:"%1",warehouse:"%2",pono:"%3",grnno:"%4"}', Company_Name, Rec."Location Code", Rec."Order No.", Rec."Document No.");
        if CallAPIService_POST(FunctionsName, JsonRequestStr, APIResult, DocumentNo) then begin
            JArrayData.ReadFrom(APIResult);
            foreach JToken in JArrayData do begin
                JObjectData := JToken.AsObject();
                if JObjectData.Get('Status', JToken) then
                    llStatus := JToken.AsValue().AsBoolean();
                if JObjectData.Get('Message', JToken) then
                    ErrorMsg := JToken.AsValue().AsText();
                if NOT llStatus then begin
                    if ErrorMsg <> '' then
                        ERROR(ErrorMsg)
                    else
                        ERROR('Can Not Undo Receipt.\API Data: %1', APIResult);
                    exit;
                end else begin
                    if InterfaceDocumentStatus.Get(InterfaceDocumentStatus."BPC.Document Type"::GRN, DocumentNo) then begin
                        InterfaceDocumentStatus."BPC.Posted At FO" := true;
                        InterfaceDocumentStatus.MODIFY;
                    end;
                end;
            end;
        end else
            ERROR('%1', GETLASTERRORTEXT);
    end;
    // procedure SendUndoReceipt(var Rec: Record "Purch. Rcpt. Line")
    // var
    //     UndoPurchRcpLine: Codeunit "Undo Purchase Receipt Line";
    //     PurchRcptLine: Record "Purch. Rcpt. Line";
    //     llStatus: Boolean;
    //     ItemLedgEntry: Record "Item Ledger Entry";
    //     PostStatus: Boolean;
    // begin
    //     Clear(JsonRequestStr);
    //     Clear(APIResult);
    //     Clear(ErrorMsg);
    //     CheckConfigInterface();

    //     if Rec.FindSet() then;

    //     if NOT CONFIRM(Text000, TRUE, Rec."Document No.") then
    //         exit;

    //     ItemLedgEntry.Reset();
    //     ItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type"::Purchase);
    //     ItemLedgEntry.SetRange("Document No.", Rec."Document No.");
    //     //ItemLedgEntry.SetRange("Document Line No.",Rec."Line No.");
    //     ItemLedgEntry.SetRange("Document Type", ItemLedgEntry."Document Type"::"Purchase Receipt");
    //     ItemLedgEntry.SetRange(Positive, TRUE);
    //     if ItemLedgEntry.FindSet() then
    //         repeat
    //             if ItemLedgEntry.Quantity <> ItemLedgEntry."Remaining Quantity" then
    //                 ERROR(StrSubstNo('Item No.: %1\Receiving Quantity: %2\Current Remaining: %3', ItemLedgEntry."Item No.", ItemLedgEntry.Quantity, ItemLedgEntry."Remaining Quantity"));
    //         until ItemLedgEntry.Next() = 0;
    //     PurchRcptLine.Reset();
    //     PurchRcptLine.SetRange("Document No.", Rec."Document No.");
    //     PurchRcptLine.SetRange("Order No.", Rec."Order No.");
    //     PurchRcptLine.SETFILTER(Quantity, '<>%1', 0);
    //     PurchRcptLine.SetRange(Correction, FALSE);
    //     if PurchRcptLine.FindSet() then begin
    //         Clear(UndoPurchRcpLine);
    //         //UndoPurchRcpLine.SetInterfaceData();
    //         UndoPurchRcpLine.SetHideDialog(TRUE);
    //         PostStatus := UndoPurchRcpLine.RUN(PurchRcptLine);
    //         if PostStatus then begin
    //             Message('Line No. %1 Item No %2 Undo Receipt Complete.', Rec."Line No.", Rec."No.");
    //         end else begin
    //             ERROR('%1', GETLASTERRORTEXT);
    //         end;
    //         //     Message('Line No. %1 Item No %2 Undo Receipt Complete.', Rec."Line No.", Rec."No.");
    //     end;
    /*FunctionsName := 'SendUndoReceipt';
    DocumentNo := Rec."Document No.";
    JsonRequestStr := StrSubstNo('{company:"%1",warehouse:"%2",pono:"%3",grnno:"%4"}',Company_Name,Rec."Location Code",Rec."Order No.",Rec."Document No.");
    if CallAPIService(FunctionsName,JsonRequestStr,APIResult) then begin
      Clear(JSONMgt);
      JSONMgt.InitializeCollection(APIResult);
      JSONMgt.GetJsonArray(JArrayData);
      foreach JObjectData in JArrayData do begin
        EVALUATE(llStatus,FuncCenter.GetValueEnpty(3,FORMAT(JObjectData.GetValue('Status'))));
        ErrorMsg := FuncCenter.GetValueEnpty(2,FORMAT(JObjectData.GetValue('Message')));
        if NOT llStatus then begin
          if ErrorMsg <> '' then
            Message(Text001,ErrorMsg)
          else
            Message('Can Not Undo Receipt.\API Data: %1',APIResult);
          exit;
        end;
        PurchRcptLine.Reset();
        PurchRcptLine.SetRange("Document No.",Rec."Document No.");
        PurchRcptLine.SetRange("Order No.",Rec."Order No.");
        PurchRcptLine.SETFILTER(Quantity,'<>%1',0);
        PurchRcptLine.SetRange(Correction,FALSE);
        if PurchRcptLine.FindSet() then begin
          Clear(UndoPurchRcpLine);
          UndoPurchRcpLine.SetInterfaceData();
          UndoPurchRcpLine.SetHideDialog(TRUE);
          UndoPurchRcpLine.RUN(PurchRcptLine);
          Message('Line No. %1 Item No %2 Undo Receipt Complete.',Rec."Line No.",Rec."No.");
        end;
      end;
    end else
      Message('%1',GETLASTERRORTEXT);*/
    // end;
    // procedure SetInterfaceData()
    // var
    //     IsInterfaceData: Boolean;
    // begin
    //     IsInterfaceData := true;
    // end;

    //ReSendPostTransfersShipment
    procedure PostTransfersShipment(var Rec: Record "Transfer Header")
    var
        TransferPostShipment: Codeunit "TransferOrder-Post Shipment";
        TransHeader: Record "Transfer Header";
        llStatus: Boolean;
        lcOrderNo: Text;
        lcShipmentNo: Text;
        PostStatus: Boolean;
    begin
        Clear(JsonRequestStr);
        Clear(APIResult);
        Clear(RecRef);
        Clear(ErrorMsg);
        CheckConfigInterface();
        RecRef.GetTable(Rec);
        FunctionsName := 'PostTransfersShipment';
        DocumentNo := Rec."No.";
        JsonRequestStr := CreateJsonRequestStr(FunctionsName, RecRef);
        JsonRequestStr := Convert.ToBase64(JsonRequestStr);
        JsonRequestStr := StrSubstNo('{company:"%1",warehouse:"%2",shipment:"%3"}', Company_Name, Rec."Transfer-from Code", JsonRequestStr);

        if CallAPIService_POST(FunctionsName, JsonRequestStr, APIResult, DocumentNo) then begin
            JArrayData.ReadFrom(APIResult);
            foreach JToken in JArrayData do begin
                JObjectData := JToken.AsObject();
                if JObjectData.Get('Status', JToken) then
                    llStatus := JToken.AsValue().AsBoolean();
                if JObjectData.Get('TransferOrderNo', JToken) then
                    lcOrderNo := JToken.AsValue().AsText();
                if JObjectData.Get('ShipmentNo', JToken) then
                    lcShipmentNo := JToken.AsValue().AsText();
                if JObjectData.Get('Message', JToken) then
                    ErrorMsg := JToken.AsValue().AsText();
                if NOT llStatus then begin
                    if ErrorMsg <> '' then
                        Message(Text001, ErrorMsg)
                    else
                        Message('Can Not Post Ship.');
                    exit;
                end;
                Message('Transfer No. %1 has been Post Shipment.', lcOrderNo);
            end;
        end else
            Message('%1', GetLastErrorText());


    end;

    procedure PostTransfersReceiptJob(var Rec: Record "Transfer Receipt Header"; HideDialog: Boolean; ErrText: Text)
    var
        TransferPostReceipt: Codeunit "TransferOrder-Post Receipt";
        TransHeader: Record "Transfer Header";
        llStatus: Boolean;
        lcOrderNo: Text;
        lcReceiptNo: Text;
        TransferReceiptHeader: Record "Transfer Receipt Header";
    begin
        //hide dialog, error text use for Auto post receive
        Clear(JsonRequestStr);
        Clear(APIResult);
        Clear(RecRef);
        Clear(ErrorMsg);
        CheckConfigInterface();

        //RecRef.GetTable(Rec);
        FunctionsName := 'PostTransfersReceipt';
        TransferReceiptHeader.Reset();
        TransferReceiptHeader.SetRange("Transfer Order No.", rec."Transfer Order No.");
        if TransferReceiptHeader.FindSet() then begin
            RecRef.GetTable(TransferReceiptHeader);
        end;

        DocumentNo := Rec."No.";
        JsonRequestStr := Convert.ToBase64(CreateJsonRequestStr(FunctionsName, RecRef));
        JsonRequestStr := StrSubstNo('{company:"%1",warehouse:"%2",receipt:"%3"}', Company_Name, Rec."Transfer-from Code", JsonRequestStr);
        if CallAPIService_POST(FunctionsName, JsonRequestStr, APIResult, DocumentNo) then begin
            JArrayData.ReadFrom(APIResult);
            foreach JToken in JArrayData do begin
                JObjectData := JToken.AsObject();
                if JObjectData.Get('Status', JToken) then
                    llStatus := JToken.AsValue().AsBoolean();
                if JObjectData.Get('TransferOrderNo', JToken) then
                    lcOrderNo := JToken.AsValue().AsText();
                if JObjectData.Get('ReceiptNo', JToken) then
                    lcReceiptNo := JToken.AsValue().AsText();
                if JObjectData.Get('Message', JToken) then
                    ErrorMsg := JToken.AsValue().AsText();

                // if NOT llStatus then begin
                //     if NOT HideDialog then begin
                //         if ErrorMsg <> '' then
                //             Message(Text001, ErrorMsg)
                //         else
                //             Message('Can Not Post Receipt.');
                //         exit;
                //     end else begin
                //         ErrText := ErrorMsg;
                //         exit;
                //     end;
                // end;
                // if NOT HideDialog then
                //     Message('Transfer No. %1 has been Post Receipt.', lcReceiptNo);

            end;
        end;
        // end else
        //     if NOT HideDialog then
        //         Message('%1', GetLastErrorText());
    end;

    procedure PostTransfersReceipt(var Rec: Record "Transfer Header"; HideDialog: Boolean; ErrText: Text)
    var
        TransferPostReceipt: Codeunit "TransferOrder-Post Receipt";
        TransHeader: Record "Transfer Header";
        llStatus: Boolean;
        lcOrderNo: Text;
        lcReceiptNo: Text;
        TransferReceiptHeader: Record "Transfer Receipt Header";
    begin
        //hide dialog, error text use for Auto post receive
        Clear(JsonRequestStr);
        Clear(APIResult);
        Clear(RecRef);
        Clear(ErrorMsg);
        CheckConfigInterface();

        //RecRef.GetTable(Rec);
        FunctionsName := 'PostTransfersReceipt';
        TransferReceiptHeader.Reset();
        TransferReceiptHeader.SetRange("Transfer Order No.", rec."No.");
        if TransferReceiptHeader.FindSet() then begin
            RecRef.GetTable(TransferReceiptHeader);
        end;

        DocumentNo := Rec."No.";
        JsonRequestStr := Convert.ToBase64(CreateJsonRequestStr(FunctionsName, RecRef));
        JsonRequestStr := StrSubstNo('{company:"%1",warehouse:"%2",receipt:"%3"}', Company_Name, Rec."Transfer-from Code", JsonRequestStr);
        if CallAPIService_POST(FunctionsName, JsonRequestStr, APIResult, DocumentNo) then begin
            JArrayData.ReadFrom(APIResult);
            foreach JToken in JArrayData do begin
                JObjectData := JToken.AsObject();
                if JObjectData.Get('Status', JToken) then
                    llStatus := JToken.AsValue().AsBoolean();
                if JObjectData.Get('TransferOrderNo', JToken) then
                    lcOrderNo := JToken.AsValue().AsText();
                if JObjectData.Get('ReceiptNo', JToken) then
                    lcReceiptNo := JToken.AsValue().AsText();
                if JObjectData.Get('Message', JToken) then
                    ErrorMsg := JToken.AsValue().AsText();
                if NOT llStatus then begin
                    if NOT HideDialog then begin
                        if ErrorMsg <> '' then
                            Message(Text001, ErrorMsg)
                        else
                            Message('Can Not Post Receipt.');
                        exit;
                    end else begin
                        ErrText := ErrorMsg;
                        exit;
                    end;
                end;
                if NOT HideDialog then
                    Message('Transfer No. %1 has been Post Receipt.', lcReceiptNo);
            end;
        end else
            if NOT HideDialog then
                Message('%1', GetLastErrorText());
    end;

    procedure SendExpense(var rec: Record "Purch. Inv. Header"; PurchInvHdrNo: Code[20]; HideDialog: Boolean; ErrText: Text)
    var

        llStatus: Boolean;
        lcOrderNo: Text;
        lcShipNO: Text;
        SuppressCommit: Boolean;
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        JournalID: text;
    begin
        Clear(JsonRequestStr);
        Clear(APIResult);
        Clear(ErrorMsg);
        PurchInvHeader.Reset();
        PurchInvHeader.SetRange("No.", PurchInvHdrNo);
        if not PurchInvHeader.FindSet() then
            PurchInvHeader.Init();
        CheckConfigInterface();
        FunctionsName := 'SendExpense';
        DocumentNo := PurchInvHeader."Vendor Invoice No.";
        JsonRequestStr := Convert.ToBase64(CreateJsonSendExpense(FunctionsName, PurchInvHdrNo));
        JsonRequestStr := StrSubstNo('{company:"%1",warehouse:"%2",data:"%3"}', Company_Name, rec."Location Code", JsonRequestStr);
        if CallAPIService_POST(FunctionsName, JsonRequestStr, APIResult, DocumentNo) then begin
            Clear(JSONMgt);
            JArrayData.ReadFrom(APIResult);
            foreach JToken in JArrayData do begin
                JObjectData := JToken.AsObject();
                if JObjectData.Get('Status', JToken) then
                    llStatus := JToken.AsValue().AsBoolean();
                if JObjectData.Get('Message', JToken) then
                    ErrorMsg := JToken.AsValue().AsText();
                if JObjectData.Get('JournalID', JToken) then
                    JournalID := JToken.AsValue().AsText();

                if NOT llStatus then begin
                    // PurchInvHeader.Reset();
                    // PurchInvHeader.SetRange("No.", PurchInvHdrNo);
                    // if PurchInvHeader.FindSet() then begin
                    //     PurchInvHeader."BPC.To D365" := true;
                    //     PurchInvHeader.Modify();
                    // end;
                    if ErrorMsg <> '' then
                        Message(Text001, ErrorMsg)
                    else
                        Message('%1', GetLastErrorText());
                end else begin
                    Message('Journal number %1 has been', JournalID);
                end;
            end;
        end else begin
            // PurchInvHeader.Reset();
            // PurchInvHeader.SetRange("No.", PurchInvHdrNo);
            // if PurchInvHeader.FindSet() then begin
            //     PurchInvHeader."BPC.To D365" := true;
            //     PurchInvHeader.Modify();
            // end;
            Message('%1', GetLastErrorText());
        end;
    end;


    procedure SendCheckSerial(var TransLine: Record "LSC POS Trans. Line"; SerialNo: Code[20]; var ErrorText: Text[250]): Boolean
    var
        llStatus: Boolean;
        lnStock: Decimal;
        lcFIFO: Text;
        lcStatus: Text;
        item: Record Item;
    begin
        Clear(JsonRequestStr);
        Clear(APIResult);
        CheckConfigInterface();
        if (SerialNo = '') then begin
            ErrorText := StrSubstNo('Item: %1\%2\Serial No. must not be blank.', TransLine.Number, TransLine.Description);
            EXIT(FALSE);
        end;

        if NOT Store.Get(TransLine."Store No.") then
            Store.Init();

        ItemVariantRegistration.Reset();
        ItemVariantRegistration.SETFILTER("Item No.", '%1', TransLine.Number);
        ItemVariantRegistration.SETFILTER(Variant, '%1', TransLine."Variant Code");
        if NOT ItemVariantRegistration.FindSet() then
            ItemVariantRegistration.Init();

        FunctionsName := 'SendCheckSerial';
        DocumentNo := TransLine."Receipt No.";
        JsonRequestStr := StrSubstNo('{company:"%1",warehouse:"%2",itemid:"%3",variant:"%4",serial:"%5"}',
                                      Company_Name, Store."Location Code", TransLine.Number, ItemVariantRegistration."Variant Dimension 1", SerialNo);
        if CallAPIService_POST(FunctionsName, JsonRequestStr, APIResult, DocumentNo) then begin
            Clear(JSONMgt);
            // JSONMgt.InitializeCollection(APIResult);
            // JSONMgt.GetJsonArray(JArrayData);
            JArrayData.ReadFrom(APIResult);
            foreach JToken in JArrayData do begin
                JObjectData := JToken.AsObject();
                if JObjectData.Get('stock', JToken) then
                    lnStock := JToken.AsValue().AsDecimal();
                if JObjectData.Get('FIFO', JToken) then
                    lcFIFO := JToken.AsValue().AsText();
                if JObjectData.Get('Status', JToken) then
                    lcStatus := JToken.AsValue().AsText();
                // foreach JObjectData in JArrayData do begin
                //     EVALUATE(lnStock, FuncCenter.GetValueEnpty(1, FORMAT(JObjectData.GetValue('stock'))));
                //     lcFIFO := StrSubstNo('%1', FuncCenter.GetValueEnpty(3, FORMAT(JObjectData.GetValue('FIFO'))));
                //     lcStatus := FuncCenter.GetValueEnpty(2, FORMAT(JObjectData.GetValue('Status')));
                if (lnStock > 0) then begin
                    ErrorText := '';
                    llStatus := true;
                    if (lcFIFO = 'N') then
                        if NOT EposCtrl.PosConfirm(StrSubstNo('Item: %1\%2\Serial No. %3 is not FIFO.,To be continued?', TransLine.Number, TransLine.Description, SerialNo), TRUE) then
                            llStatus := FALSE;
                end else
                    if lcStatus = 'S' then begin
                        ErrorText := StrSubstNo('Item: %1\%2\Serial No. %3 is Sold.', TransLine.Number, TransLine.Description, SerialNo);
                        llStatus := FALSE;
                    end else begin
                        ErrorText := StrSubstNo('Item: %1\%2\Serial No. %3 does not exist.', TransLine.Number, TransLine.Description, SerialNo);
                        llStatus := FALSE;
                    end;
                EXIT(llStatus);
            end;
        end else
            Message('%1', GetLastErrorText());
    end;

    procedure SendCheckSerialInStock(SerialNo: Code[50]; var pItemNo: Text; var pVariant: Text; var pVariantName: Text): Boolean
    var
        lnStock: Decimal;
        InItem: Text;
        InVariant: Text;
        InVariantName: Text;
        Item: Record Item;
        ErrorText: Text;
    begin
        Clear(JsonRequestStr);
        Clear(APIResult);
        CheckConfigInterface();

        if (SerialNo = '') then begin
            ErrorText := StrSubstNo('Serial No. must not be blank.');
            EXIT(FALSE);
        end;

        Clear(pItemNo);
        Clear(pVariant);
        Clear(pVariantName);

        FunctionsName := 'CheckSerialExist';
        JsonRequestStr := StrSubstNo('{company:"%1",serial:"%2"}', Company_Name, SerialNo);
        if CallAPIService_POST(FunctionsName, JsonRequestStr, APIResult, DocumentNo) then begin
            Clear(JSONMgt);
            // JSONMgt.InitializeCollection(APIResult);
            // JSONMgt.GetJsonArray(JArrayData);
            JArrayData.ReadFrom(APIResult);
            foreach JToken in JArrayData do begin
                JObjectData := JToken.AsObject();
                if JObjectData.Get('Quantity', JToken) then
                    lnStock := JToken.AsValue().AsDecimal();
                if JObjectData.Get('ItemNo', JToken) then
                    InItem := JToken.AsValue().AsText();
                if JObjectData.Get('Variant', JToken) then
                    InVariant := JToken.AsValue().AsText();
                if JObjectData.Get('VariantName', JToken) then
                    InVariantName := JToken.AsValue().AsText();
                // foreach JObjectData in JArrayData do begin
                //     EVALUATE(lnStock, FuncCenter.GetValueEnpty(1, FORMAT(JObjectData.GetValue('Quantity'))));
                //     EVALUATE(InItem, FuncCenter.GetValueEnpty(1, FORMAT(JObjectData.GetValue('ItemNo'))));
                //     EVALUATE(InVariant, FuncCenter.GetValueEnpty(1, FORMAT(JObjectData.GetValue('Variant'))));
                //     EVALUATE(InVariantName, FuncCenter.GetValueEnpty(1, FORMAT(JObjectData.GetValue('VariantName'))));
                pItemNo := InItem;
                pVariant := InVariant;
                pVariantName := InVariantName;
                if (lnStock > 0) then
                    EXIT(TRUE);
                EXIT(FALSE);
            end;
        end else
            Message('%1', GetLastErrorText());
    end;

    procedure SendCheckStock(NewQuantity: Decimal; var TransLine: Record "LSC POS Trans. Line"; var ErrorText: Text[250]): Boolean
    var
        llStatus: Boolean;
        lnStockQty: Decimal;
        BOUtils: Codeunit "LSC BO Utils";
        QtySoldNotPst: Decimal;
    begin
        Clear(JsonRequestStr);
        Clear(APIResult);
        CheckConfigInterface();

        if NOT Store.Get(TransLine."Store No.") then
            Store.Init();

        ItemVariantRegistration.Reset();
        ItemVariantRegistration.SETFILTER("Item No.", '%1', TransLine.Number);
        ItemVariantRegistration.SETFILTER(Variant, '%1', TransLine."Variant Code");
        if NOT ItemVariantRegistration.FindSet() then
            ItemVariantRegistration.Init();

        FunctionsName := 'SendCheckStock';
        DocumentNo := TransLine."Receipt No.";
        JsonRequestStr := StrSubstNo('{company:"%1",warehouse:"%2",itemid:"%3",variant:"%4"}',
                                      Company_Name, Store."Location Code", TransLine.Number, ItemVariantRegistration."Variant Dimension 1");
        if CallAPIService_POST(FunctionsName, JsonRequestStr, APIResult, DocumentNo) then begin
            Clear(JSONMgt);
            //JSONMgt.InitializeCollection(APIResult);
            //JSONMgt.GetJsonArray(JArrayData);
            JArrayData.ReadFrom(APIResult);
            foreach JToken in JArrayData do begin
                JObjectData := JToken.AsObject();

                if JObjectData.Get('Quantity', JToken) then
                    lnStockQty := JToken.AsValue().AsDecimal();
                //EVALUATE(lnStockQty, FuncCenter.GetValueEnpty(1, FORMAT(JArrayData.GetValue('Quantity'))));

                lnStockQty -= BOUtils.ReturnQtySoldNotPosted(TransLine.Number, Store."No.", Store."Location Code", TransLine."Variant Code", ''); //DRL
                llStatus := true;
                if (lnStockQty <= 0) OR (NewQuantity > lnStockQty) then begin
                    ErrorText := StrSubstNo('Item: %1\%2\Variant: %3\Qty. In Stock %4,\Can Not Sales. in Store: %5', TransLine.Number, TransLine.Description, TransLine."Variant Code", lnStockQty, Store."Location Code");
                    llStatus := FALSE;
                end;
                EXIT(llStatus);
            end;
        end else
            Message('%1', GetLastErrorText());
    end;

    procedure SendCloseBill(var Transaction: Record "LSC Transaction Header")
    var
        TransSalesEntry: Record "LSC Trans. Sales Entry";
        Item: Record Item;
        llStatus: Boolean;
        lnAvailQty: Decimal;
    begin
        if Transaction."Entry Status" = Transaction."Entry Status"::Voided then
            exit;

        Clear(JsonRequestStr);
        Clear(APIResult);
        Clear(ErrorMsg);
        CheckConfigInterface();

        TransSalesEntry.Reset();
        TransSalesEntry.SetRange("Store No.", Transaction."Store No.");
        TransSalesEntry.SetRange("POS Terminal No.", Transaction."POS Terminal No.");
        TransSalesEntry.SetRange("Transaction No.", Transaction."Transaction No.");
        if TransSalesEntry.FIND('-') then
            repeat
                if NOT Item.Get(TransSalesEntry."Item No.") then
                    Item.Init();
                if Item."Item Tracking Code" = 'SERIAL' then begin
                    if NOT Store.Get(TransSalesEntry."Store No.") then
                        Store.Init();

                    ItemVariantRegistration.Reset();
                    ItemVariantRegistration.SETFILTER("Item No.", '%1', TransSalesEntry."Item No.");
                    ItemVariantRegistration.SETFILTER(Variant, '%1', TransSalesEntry."Variant Code");
                    if NOT ItemVariantRegistration.FindSet() then
                        ItemVariantRegistration.Init();

                    FunctionsName := 'SendCloseBill';
                    DocumentNo := Transaction."Receipt No.";
                    JsonRequestStr := StrSubstNo('{company:"%1",warehouse:"%2",itemid:"%3",variant:"%4",serial:"%5"}',
                                                  Company_Name, Store."Location Code", TransSalesEntry."Item No.", ItemVariantRegistration."Variant Dimension 1", TransSalesEntry."Serial No.");
                    if CallAPIService_POST(FunctionsName, JsonRequestStr, APIResult, DocumentNo) then begin
                        Clear(JSONMgt);
                        // JSONMgt.InitializeCollection(APIResult);
                        // JSONMgt.GetJsonArray(JArrayData);
                        JArrayData.ReadFrom(APIResult);
                        foreach JToken in JArrayData do begin
                            JObjectData := JToken.AsObject();
                            if JObjectData.Get('Status', JToken) then
                                llStatus := JToken.AsValue().AsBoolean();
                            if JObjectData.Get('Message', JToken) then
                                ErrorMsg := JToken.AsValue().AsText();
                            // foreach JObjectData in JArrayData do begin
                            //     EVALUATE(llStatus, FuncCenter.GetValueEnpty(3, FORMAT(JObjectData.GetValue('Status'))));
                            //     ErrorMsg := FuncCenter.GetValueEnpty(2, FORMAT(JObjectData.GetValue('Message')));
                            if (not llStatus) AND (ErrorMsg <> '') then
                                Message(Text001, ErrorMsg);
                        end;
                    end;
                end;
            until TransSalesEntry.Next() = 0;
    end;

    procedure SendVoidBill(var Transaction: Record "LSC Transaction Header")
    var
        TransSalesEntry: Record "LSC Trans. Sales Entry";
        Item: Record Item;
        llStatus: Boolean;
        lnAvailQty: Decimal;
    begin
        if Transaction."Entry Status" = Transaction."Entry Status"::Voided then
            exit;

        Clear(JsonRequestStr);
        Clear(APIResult);
        Clear(ErrorMsg);
        CheckConfigInterface();

        TransSalesEntry.Reset();
        TransSalesEntry.SetRange("Store No.", Transaction."Store No.");
        TransSalesEntry.SetRange("POS Terminal No.", Transaction."POS Terminal No.");
        TransSalesEntry.SetRange("Transaction No.", Transaction."Transaction No.");
        if TransSalesEntry.FIND('-') then
            repeat
                if NOT Item.Get(TransSalesEntry."Item No.") then
                    Item.Init();
                if Item."Item Tracking Code" = 'SERIAL' then begin
                    if NOT Store.Get(TransSalesEntry."Store No.") then
                        Store.Init();

                    ItemVariantRegistration.Reset();
                    ItemVariantRegistration.SETFILTER("Item No.", '%1', TransSalesEntry."Item No.");
                    ItemVariantRegistration.SETFILTER(Variant, '%1', TransSalesEntry."Variant Code");
                    if NOT ItemVariantRegistration.FindSet() then
                        ItemVariantRegistration.Init();

                    FunctionsName := 'SendVoidBill';
                    DocumentNo := Transaction."Receipt No.";
                    JsonRequestStr := StrSubstNo('{company:"%1",warehouse:"%2",itemid:"%3",variant:"%4",serial:"%5"}',
                                                  Company_Name, Store."Location Code", TransSalesEntry."Item No.", ItemVariantRegistration."Variant Dimension 1", TransSalesEntry."Serial No.");
                    if CallAPIService_POST(FunctionsName, JsonRequestStr, APIResult, DocumentNo) then begin
                        Clear(JSONMgt);
                        // JSONMgt.InitializeCollection(APIResult);
                        // JSONMgt.GetJsonArray(JArrayData);
                        JArrayData.ReadFrom(APIResult);
                        foreach JToken in JArrayData do begin
                            JObjectData := JToken.AsObject();
                            if JObjectData.Get('Status', JToken) then
                                llStatus := JToken.AsValue().AsBoolean();
                            if JObjectData.Get('Message', JToken) then
                                ErrorMsg := JToken.AsValue().AsText();
                            // foreach JObjectData in JArrayData do begin
                            //     EVALUATE(llStatus, FuncCenter.GetValueEnpty(3, FORMAT(JObjectData.GetValue('Status'))));
                            //     ErrorMsg := FuncCenter.GetValueEnpty(2, FORMAT(JObjectData.GetValue('Message')));
                            if (not llStatus) AND (ErrorMsg <> '') then
                                Message(Text001, ErrorMsg);
                        end;
                    end;
                end;
            until TransSalesEntry.Next() = 0;
    end;

    procedure SendChkInvenLookupInStock(var pCurrlineTemp: Record "LSC POS Trans. Line"; var plInvLookuptmp: Record "LSC Inventory Lookup Table" temporary)
    var
        StockLocation: Record "LSC Store Location";
        Var_ItemNo: Text;
        Var_Warehouse: Text;
        Var_Quantity: Decimal;
        Var_Variant: Text;
        Var_SerialNo: Text;
    begin
        Clear(JsonRequestStr);
        Clear(APIResult);
        Clear(ErrorMsg);
        CheckConfigInterface();

        StockLocation.Reset();
        StockLocation.SetRange("Store No.", pCurrlineTemp."Store No.");
        if StockLocation.FindSet() then begin
            repeat
                FunctionsName := 'SendChkInvenLookupInStock';
                DocumentNo := pCurrlineTemp."Receipt No.";
                JsonRequestStr := StrSubstNo('{company:"%1",warehouse:"%2",item:"%3"}', Company_Name, StockLocation."Store No.", pCurrlineTemp.Number);
                if CallAPIService_POST(FunctionsName, JsonRequestStr, APIResult, DocumentNo) then begin
                    Clear(JSONMgt);
                    // JSONMgt.InitializeCollection(APIResult);
                    // JSONMgt.GetJsonArray(JArrayData);
                    JArrayData.ReadFrom(APIResult);
                    foreach JToken in JArrayData do begin
                        JObjectData := JToken.AsObject();
                        if JObjectData.Get('ItemNo', JToken) then
                            Var_ItemNo := JToken.AsValue().AsText();
                        if JObjectData.Get('Warehouse', JToken) then
                            Var_Warehouse := JToken.AsValue().AsText();
                        if JObjectData.Get('Quantity', JToken) then
                            Var_Quantity := JToken.AsValue().AsDecimal();
                        if JObjectData.Get('Variant', JToken) then
                            Var_Variant := JToken.AsValue().AsText();
                        if JObjectData.Get('SerialNo', JToken) then
                            Var_SerialNo := JToken.AsValue().AsText();
                        // foreach JObjectData in JArrayData do begin
                        //     Var_ItemNo := FuncCenter.GetValueEnpty(2, FORMAT(JObjectData.GetValue('ItemNo')));
                        //     Var_Warehouse := FuncCenter.GetValueEnpty(2, FORMAT(JObjectData.GetValue('Warehouse')));
                        //     EVALUATE(Var_Quantity, FuncCenter.GetValueEnpty(1, FORMAT(JObjectData.GetValue('Quantity'))));
                        //     Var_Variant := FuncCenter.GetValueEnpty(2, FORMAT(JObjectData.GetValue('Variant')));
                        //     Var_SerialNo := FuncCenter.GetValueEnpty(2, FORMAT(JObjectData.GetValue('SerialNo')));

                        if Var_ItemNo <> '' then begin
                            if Var_Variant <> '' then begin
                                ItemVariantRegistration.Reset();
                                ItemVariantRegistration.SETFILTER("Item No.", '%1', Var_ItemNo);
                                ItemVariantRegistration.SETFILTER("Variant Dimension 1", '%1', Var_Variant);
                                if NOT ItemVariantRegistration.FindSet() then
                                    ItemVariantRegistration.Init();
                                Var_Variant := ItemVariantRegistration.Variant;
                            end;

                            plInvLookuptmp.Reset();
                            plInvLookuptmp.SETFILTER("Item No.", '%1', Var_ItemNo);
                            plInvLookuptmp.SETFILTER("Variant Code", '%1', Var_Variant);
                            plInvLookuptmp.SETFILTER(Location, '%1', Var_Warehouse);
                            plInvLookuptmp.SETFILTER("Serial No.", '%1', Var_SerialNo);
                            if NOT plInvLookuptmp.FindSet() then begin
                                plInvLookuptmp.Init();
                                plInvLookuptmp."Item No." := Var_ItemNo;
                                plInvLookuptmp."Variant Code" := Var_Variant;
                                plInvLookuptmp."Store No." := pCurrlineTemp."Store No.";
                                plInvLookuptmp."Serial No." := Var_SerialNo;
                                plInvLookuptmp.Location := Var_Warehouse;
                                plInvLookuptmp."BPC.Stock On D365" := Var_Quantity;
                                plInvLookuptmp.UpdateInventory2;
                                plInvLookuptmp.Insert();
                            end else begin
                                plInvLookuptmp."BPC.Stock On D365" += Var_Quantity;
                                plInvLookuptmp.MODIFY
                            end;
                        end;
                    end;
                end;
            until StockLocation.Next() = 0;
        end;
    end;

    procedure PostInventCountingJournal(pWorksheetSeqNo: Integer; var llStatus: Boolean)
    var
        StoreInventoryWorksheet: Record "LSC Store Inventory Worksheet";
        lcTransferJournalID: Text;

    begin
        Clear(JsonRequestStr);
        Clear(APIResult);
        Clear(RecRef);
        Clear(ErrorMsg);
        CheckConfigInterface();

        if StoreInventoryWorksheet.Get(pWorksheetSeqNo) then begin
            RecRef.GetTable(StoreInventoryWorksheet);
            FunctionsName := 'PostInventCountingJournal';
            DocumentNo := StrSubstNo('%1', StoreInventoryWorksheet.WorksheetSeqNo);
            JsonRequestStr := Convert.ToBase64(CreateJsonRequestStr(FunctionsName, RecRef));
            // JsonRequestStr := Convert.ToBase64String(Encoding.UTF8.GetBytes(CreateJsonRequestStr(FunctionsName, RecRef)));
            JsonRequestStr := StrSubstNo('{company:"%1",warehouse:"%2",journaldata:"%3"}', Company_Name, StoreInventoryWorksheet."Location Code", JsonRequestStr);
            if CallAPIService_POST(FunctionsName, JsonRequestStr, APIResult, DocumentNo) then begin
                Clear(JSONMgt);
                // JSONMgt.InitializeCollection(APIResult);
                // JSONMgt.GetJsonArray(JArrayData);
                JArrayData.ReadFrom(APIResult);
                foreach JToken in JArrayData do begin
                    JObjectData := JToken.AsObject();
                    if JObjectData.Get('Status', JToken) then
                        llStatus := JToken.AsValue().AsBoolean();
                    if JObjectData.Get('JournalID', JToken) then
                        lcTransferJournalID := JToken.AsValue().AsText();
                    if JObjectData.Get('Message', JToken) then
                        ErrorMsg := JToken.AsValue().AsText();
                    if NOT llStatus then begin
                        if ErrorMsg <> '' then
                            Message(Text001, ErrorMsg)
                        else
                            Message('Can Not Post Invent Counting Journal.');
                        exit;
                    end;

                    InsertPostedStoreInventoryLine(pWorksheetSeqNo, lcTransferJournalID);
                    Message('WorksheetSeqNo. %1 has been Post Invent Counting Journal.', StoreInventoryWorksheet.Description);
                end;
            end else
                Message('%1', GetLastErrorText());
        end;
    end;

    procedure PostItemJournal(pWorksheetSeqNo: Integer)
    var
        StoreInventoryWorksheet: Record "LSC Store Inventory Worksheet";
        lcTransferJournalID: Text;
        llStatus: Boolean;
        TMPItemLedgEntry: Record "BPC.TMPItemLedgEntry";
    begin
        Clear(JsonRequestStr);
        Clear(APIResult);
        Clear(RecRef);
        Clear(ErrorMsg);
        CheckConfigInterface();

        if StoreInventoryWorksheet.Get(pWorksheetSeqNo) then begin
            RecRef.GetTable(StoreInventoryWorksheet);
            FunctionsName := 'PostItemJournal';
            DocumentNo := StrSubstNo('%1', StoreInventoryWorksheet.WorksheetSeqNo);
            // TMPItemLedgEntry.Reset();
            // TMPItemLedgEntry.SetRange(TMPItemLedgEntry."User ID", UserId);
            // if TMPItemLedgEntry.FindSet() then begin
            //     DocumentNo := StrSubstNo('%1', TMPItemLedgEntry."Document No.");
            // end;
            JsonRequestStr := Convert.ToBase64(CreateJsonRequestStr(FunctionsName, RecRef));
            JsonRequestStr := StrSubstNo('{company:"%1",warehouse:"%2",journaldata:"%3"}', Company_Name, StoreInventoryWorksheet."Location Code", JsonRequestStr);
            if CallAPIService_POST(FunctionsName, JsonRequestStr, APIResult, DocumentNo) then begin
                Clear(JSONMgt);
                JArrayData.ReadFrom(APIResult);
                foreach JToken in JArrayData do begin
                    JObjectData := JToken.AsObject();
                    if JObjectData.Get('Status', JToken) then
                        llStatus := JToken.AsValue().AsBoolean();
                    if JObjectData.Get('JournalID', JToken) then
                        lcTransferJournalID := JToken.AsValue().AsText();
                    if JObjectData.Get('Message', JToken) then
                        ErrorMsg := JToken.AsValue().AsText();
                    if NOT llStatus then begin
                        if ErrorMsg <> '' then
                            Message(Text001, ErrorMsg)
                        else begin
                            Message('Can Not Post Invent Journal.');
                        end;
                        TMPItemLedgEntry.Reset();
                        TMPItemLedgEntry.SetRange(TMPItemLedgEntry."User ID", UserId);
                        TMPItemLedgEntry.SetFilter("Entry Type", '<>%1', TMPItemLedgEntry."Entry Type"::Transfer);
                        if TMPItemLedgEntry.FindSet() then begin
                            TMPItemLedgEntry.DeleteAll();
                        end;
                        exit;
                    end;

                end;
                TMPItemLedgEntry.Reset();
                TMPItemLedgEntry.SetRange(TMPItemLedgEntry."User ID", UserId);
                TMPItemLedgEntry.SetFilter("Entry Type", '<>%1', TMPItemLedgEntry."Entry Type"::Transfer);
                if TMPItemLedgEntry.FindSet() then begin
                    TMPItemLedgEntry.DeleteAll();
                end;
            end else begin
                Message('%1', GetLastErrorText());
                TMPItemLedgEntry.Reset();
                TMPItemLedgEntry.SetRange(TMPItemLedgEntry."User ID", UserId);
                TMPItemLedgEntry.SetFilter("Entry Type", '<>%1', TMPItemLedgEntry."Entry Type"::Transfer);
                if TMPItemLedgEntry.FindSet() then begin
                    TMPItemLedgEntry.DeleteAll();
                end;
            end;
        end;
    end;

    procedure PostInventAdjustJournal(pWorksheetSeqNo: Integer)
    var
        StoreInventoryWorksheet: Record "LSC Store Inventory Worksheet";
        llStatus: Boolean;
        lcTransferJournalID: Text;
    begin
        Clear(JsonRequestStr);
        Clear(APIResult);
        Clear(RecRef);
        Clear(ErrorMsg);
        CheckConfigInterface();

        if StoreInventoryWorksheet.Get(pWorksheetSeqNo) then begin
            RecRef.GetTable(StoreInventoryWorksheet);
            FunctionsName := 'PostInventAdjustJournal';
            DocumentNo := StrSubstNo('%1', StoreInventoryWorksheet.WorksheetSeqNo);
            JsonRequestStr := Convert.ToBase64(CreateJsonRequestStr(FunctionsName, RecRef));
            //JsonRequestStr := Convert.ToBase64String(Encoding.UTF8.GetBytes(CreateJsonRequestStr(FunctionsName, RecRef)));
            JsonRequestStr := StrSubstNo('{company:"%1",warehouse:"%2",journaldata:"%3"}', Company_Name, StoreInventoryWorksheet."Location Code", JsonRequestStr);
            if CallAPIService_POST(FunctionsName, JsonRequestStr, APIResult, DocumentNo) then begin
                Clear(JSONMgt);
                JArrayData.ReadFrom(APIResult);
                foreach JToken in JArrayData do begin
                    JObjectData := JToken.AsObject();
                    if JObjectData.Get('Status', JToken) then
                        llStatus := JToken.AsValue().AsBoolean();
                    if JObjectData.Get('JournalID', JToken) then
                        lcTransferJournalID := JToken.AsValue().AsText();
                    if JObjectData.Get('Message', JToken) then
                        ErrorMsg := JToken.AsValue().AsText();
                    if NOT llStatus then begin
                        if ErrorMsg <> '' then
                            Message(Text001, ErrorMsg)
                        else
                            Message('Can Not Post Invent Counting Journal.');
                        exit;
                    end;
                    JnlDocID_g := lcTransferJournalID;
                    InsertPostedStoreInventoryLine(pWorksheetSeqNo, lcTransferJournalID);
                    Message('WorksheetSeqNo. %1 has been Post Invent Counting Journal.', StoreInventoryWorksheet.Description);
                end;
            end else
                Message('%1', GetLastErrorText());
        end;
    end;

    procedure PostTransferJournal()
    var
        StoreInventoryWorksheet: Record "LSC Store Inventory Worksheet";
        lcTransferJournalID: Text;
        TMPItemLedgEntry: Record "BPC.TMPItemLedgEntry";
        Locationcode: Code[20];
        llStatus: Boolean;
    begin
        Clear(JsonRequestStr);
        Clear(APIResult);
        Clear(RecRef);
        Clear(ErrorMsg);
        Clear(Locationcode);
        CheckConfigInterface();
        FunctionsName := 'PostTransferJournal';
        TMPItemLedgEntry.Reset();
        TMPItemLedgEntry.SetRange(TMPItemLedgEntry."User ID", UserId);
        TMPItemLedgEntry.SetRange(TMPItemLedgEntry."Entry Type", TMPItemLedgEntry."Entry Type"::Transfer);
        if TMPItemLedgEntry.FindSet() then begin
            DocumentNo := StrSubstNo('%1', TMPItemLedgEntry."Document No.");
            Locationcode := TMPItemLedgEntry."BPC.Location code";
        end;
        //DocumentNo := ItemJournalLine."Document No.";
        JsonRequestStr := Convert.ToBase64(CreateJsonJournal(FunctionsName));
        JsonRequestStr := StrSubstNo('{company:"%1",warehouse:"%2",journaldata:"%3"}', Company_Name, Locationcode, JsonRequestStr);
        if CallAPIService_POST(FunctionsName, JsonRequestStr, APIResult, DocumentNo) then begin
            Clear(JSONMgt);
            if JArrayData.ReadFrom(APIResult) then begin
                foreach JToken in JArrayData do begin
                    JObjectData := JToken.AsObject();
                    if JObjectData.Get('Status', JToken) then
                        llStatus := JToken.AsValue().AsBoolean();
                    if JObjectData.Get('JournalID', JToken) then
                        lcTransferJournalID := JToken.AsValue().AsText();
                    if JObjectData.Get('Message', JToken) then
                        ErrorMsg := JToken.AsValue().AsText();
                    if NOT llStatus then begin
                        if ErrorMsg <> '' then
                            Message(Text001, ErrorMsg)
                        else
                            Message('Can Not Post Transfer Journal.');
                        exit;
                    end;
                    Message('Document No. %1 has been Post Transfer Journal.', DocumentNo);
                end;
                TMPItemLedgEntry.Reset();
                TMPItemLedgEntry.SetRange(TMPItemLedgEntry."User ID", UserId);
                TMPItemLedgEntry.SetRange("Entry Type", TMPItemLedgEntry."Entry Type"::Transfer);
                if TMPItemLedgEntry.FindSet() then begin
                    TMPItemLedgEntry.DeleteAll();
                end;
            end else begin
                Message('%1', GetLastErrorText());
                TMPItemLedgEntry.Reset();
                TMPItemLedgEntry.SetRange(TMPItemLedgEntry."User ID", UserId);
                TMPItemLedgEntry.SetRange("Entry Type", TMPItemLedgEntry."Entry Type"::Transfer);
                if TMPItemLedgEntry.FindSet() then begin
                    TMPItemLedgEntry.DeleteAll();
                end;
            end;
        end else
            Message('%1', GetLastErrorText());
        TMPItemLedgEntry.Reset();
        TMPItemLedgEntry.SetRange(TMPItemLedgEntry."User ID", UserId);
        TMPItemLedgEntry.SetRange("Entry Type", TMPItemLedgEntry."Entry Type"::Transfer);
        if TMPItemLedgEntry.FindSet() then begin
            TMPItemLedgEntry.DeleteAll();
        end;

    end;

    procedure PostItemJournals()
    var
        StoreInventoryWorksheet: Record "LSC Store Inventory Worksheet";
        lcTransferJournalID: Text;
        TMPItemLedgEntry: Record "BPC.TMPItemLedgEntry";
        Locationcode: Code[20];
        llStatus: Boolean;
    begin
        Clear(JsonRequestStr);
        Clear(APIResult);
        Clear(RecRef);
        Clear(ErrorMsg);
        Clear(Locationcode);
        CheckConfigInterface();
        //FunctionsName := 'PostTransferJournal';
        TMPItemLedgEntry.Reset();
        TMPItemLedgEntry.SetRange(TMPItemLedgEntry."User ID", UserId);
        TMPItemLedgEntry.SetRange(TMPItemLedgEntry."Entry Type", TMPItemLedgEntry."Entry Type"::"Positive Adjmt.");
        if TMPItemLedgEntry.FindSet() then begin
            DocumentNo := StrSubstNo('%1', TMPItemLedgEntry."Document No.");
            Locationcode := TMPItemLedgEntry.Warehouse;
        end;
        FunctionsName := 'PostItemJournal';
        JsonRequestStr := Convert.ToBase64(CreateJsonJournal(FunctionsName));
        JsonRequestStr := StrSubstNo('{company:"%1",warehouse:"%2",journaldata:"%3"}', Company_Name, Locationcode, JsonRequestStr);
        if CallAPIService_POST(FunctionsName, JsonRequestStr, APIResult, DocumentNo) then begin
            Clear(JSONMgt);
            JArrayData.ReadFrom(APIResult);
            foreach JToken in JArrayData do begin
                JObjectData := JToken.AsObject();
                if JObjectData.Get('Status', JToken) then
                    llStatus := JToken.AsValue().AsBoolean();
                if JObjectData.Get('JournalID', JToken) then
                    lcTransferJournalID := JToken.AsValue().AsText();
                if JObjectData.Get('Message', JToken) then
                    ErrorMsg := JToken.AsValue().AsText();
                if NOT llStatus then begin
                    if ErrorMsg <> '' then
                        Message(Text001, ErrorMsg)
                    else begin
                        Message('Can Not Post Invent Journal.');
                    end;
                    TMPItemLedgEntry.Reset();
                    TMPItemLedgEntry.SetRange(TMPItemLedgEntry."User ID", UserId);
                    TMPItemLedgEntry.SetFilter("Entry Type", '<>%1', TMPItemLedgEntry."Entry Type"::"Positive Adjmt.");
                    if TMPItemLedgEntry.FindSet() then begin
                        TMPItemLedgEntry.DeleteAll();
                    end;
                    exit;
                end;
            end;
            TMPItemLedgEntry.Reset();
            TMPItemLedgEntry.SetRange(TMPItemLedgEntry."User ID", UserId);
            TMPItemLedgEntry.SetFilter("Entry Type", '<>%1', TMPItemLedgEntry."Entry Type"::"Positive Adjmt.");
            if TMPItemLedgEntry.FindSet() then begin
                TMPItemLedgEntry.DeleteAll();
            end;
        end else begin
            Message('%1', GetLastErrorText());
            TMPItemLedgEntry.Reset();
            TMPItemLedgEntry.SetRange(TMPItemLedgEntry."User ID", UserId);
            TMPItemLedgEntry.SetFilter("Entry Type", '<>%1', TMPItemLedgEntry."Entry Type"::"Positive Adjmt.");
            if TMPItemLedgEntry.FindSet() then begin
                TMPItemLedgEntry.DeleteAll();
            end;
        end;
    end;

    procedure PostItemToFO(var Rec: Record Item)
    var
        Item: Record Item;
        APIResult: Text;
        JsonRequestStr: Text;
        llStatus: Boolean;
    begin
        Clear(JsonRequestStr);
        Clear(APIResult);
        Clear(RecRef);
        Clear(ErrorMsg);
        CheckConfigInterface();

        RecRef.GetTable(Rec);
        DocumentNo := Rec."No.";
        FunctionsName := 'createProduct';
        // JsonRequestStr := Convert.ToBase64String(Encoding.UTF8.GetBytes(CreateJsonRequestStr(FunctionsName, RecRef)));
        JsonRequestStr := Convert.ToBase64(CreateJsonRequestStr(FunctionsName, RecRef));
        JsonRequestStr := StrSubstNo('{company:"%1",Item:"%2"}', Company_Name, JsonRequestStr);
        if CallAPIService_POST(FunctionsName, JsonRequestStr, APIResult, DocumentNo) then begin
            Clear(JSONMgt);
            // JSONMgt.InitializeCollection(APIResult);
            // JSONMgt.GetJsonArray(JArrayData);
            JArrayData.ReadFrom(APIResult);
            foreach JToken in JArrayData do begin
                JObjectData := JToken.AsObject();
                if JObjectData.Get('Status', JToken) then
                    llStatus := JToken.AsValue().AsBoolean();
                if JObjectData.Get('Message', JToken) then
                    ErrorMsg := JToken.AsValue().AsText();
                // foreach JObjectData in JArrayData do begin
                //     EVALUATE(llStatus, FuncCenter.GetValueEnpty(3, FORMAT(JObjectData.GetValue('Status'))));
                //     //lcPONo := FuncCenter.GetValueEnpty(2,FORMAT(JObjectData.GetValue('PONo')));
                //     //lcGRNNo := FuncCenter.GetValueEnpty(2,FORMAT(JObjectData.GetValue('GRNNo')));
                //     ErrorMsg := FuncCenter.GetValueEnpty(2, FORMAT(JObjectData.GetValue('Message')));
                if (not llStatus) then begin // OR (lcGRNNo = '') then begin
                                             //IF ErrorMsg <> '' then
                                             //  Message(Text001,ErrorMsg)
                                             //ELSE
                                             //  Message('Can Not Create/Update Product.');
                    exit;
                end;
            end;
        end else
            Message('%1', GetLastErrorText());
    end;

    procedure PostStmtJnlToFO(var Rec: Record "LSC Posted Statement"; IsReSend: Boolean)
    var
        LocAPIResult: Text;
        LocJsonRequestStr: Text;
        IsSuccess: Boolean;
        JournalID: Text;
        Text001Lbl: Label '{company:"%1",warehouse:"%2",data:"%3"}';
        FunctionsNameLbl: Label 'postStmtJournal';
    begin
        Clear(LocJsonRequestStr);
        Clear(LocAPIResult);
        Clear(RecRef);
        Clear(ErrorMsg);

        CheckConfigInterface();
        RecRef.GetTable(Rec);
        DocumentNo := Rec."No.";
        LocJsonRequestStr := Convert.ToBase64(CreateJsonRequestStr(FunctionsNameLbl, RecRef));
        LocJsonRequestStr := StrSubstNo(Text001Lbl, Company_Name, Rec."Store No.", LocJsonRequestStr);

        if CallAPIService_POST(FunctionsNameLbl, LocJsonRequestStr, LocAPIResult, DocumentNo) then begin
            Clear(JSONMgt);
            if JArrayData.ReadFrom(LocAPIResult) then begin
                foreach JToken in JArrayData do begin
                    JObjectData := JToken.AsObject();

                    if JObjectData.Get('Status', JToken) then
                        IsSuccess := JToken.AsValue().AsBoolean();

                    if JObjectData.Get('JournalID', JToken) then
                        JournalID := JToken.AsValue().AsText();

                    if JObjectData.Get('Message', JToken) then
                        ErrorMsg := JToken.AsValue().AsText();

                    if (not IsSuccess) and (JournalID = '') then begin
                        if ErrorMsg <> '' then
                            Message(Text001, ErrorMsg)
                        else
                            Message('Can Not Create/Update Product.');
                        exit;
                    end
                end;
                // if IsReSend and IsSuccess then
                //     Message('Statement journal posted successfully!')
            end else
                Message('%1', GetLastErrorText());
        end else
            Message('%1', GetLastErrorText());
        //if IsReSend and IsSuccess then
        //Message('Statement journal posted successfully!')
    end;

    procedure PostStmtMovementToFO(var Rec: Record "LSC Posted Statement"; IsReSend: Boolean)
    var
        LocAPIResult: Text;
        LocJsonRequestStr: Text;
        IsSuccess: Boolean;
        JournalID: Text;
        Text001Lbl: Label '{company:"%1",warehouse:"%2",data:"%3"}';
        FunctionsNameLbl: Label 'postStmtMovement';
    begin
        Clear(LocJsonRequestStr);
        Clear(LocAPIResult);
        Clear(RecRef);
        Clear(ErrorMsg);

        CheckConfigInterface();
        RecRef.GetTable(Rec);
        DocumentNo := Rec."No.";
        LocJsonRequestStr := Convert.ToBase64(CreateJsonRequestStr(FunctionsNameLbl, RecRef));
        LocJsonRequestStr := StrSubstNo(Text001Lbl, Company_Name, Rec."Store No.", LocJsonRequestStr);

        if CallAPIService_POST(FunctionsNameLbl, LocJsonRequestStr, LocAPIResult, DocumentNo) then begin
            Clear(JSONMgt);
            if JArrayData.ReadFrom(LocAPIResult) then begin
                foreach JToken in JArrayData do begin
                    JObjectData := JToken.AsObject();

                    if JObjectData.Get('Status', JToken) then
                        IsSuccess := JToken.AsValue().AsBoolean();

                    if JObjectData.Get('JournalID', JToken) then
                        JournalID := JToken.AsValue().AsText();

                    if JObjectData.Get('Message', JToken) then
                        ErrorMsg := JToken.AsValue().AsText();

                    if (not IsSuccess) and (JournalID = '') then begin
                        if ErrorMsg <> '' then
                            Message(Text001, ErrorMsg)
                        else
                            Message('Can Not Create/Update Product.');
                        exit;
                    end
                end;
                // if IsReSend and IsSuccess then
                //     Message('Statement movement posted successfully!')
            end else
                Message('%1', GetLastErrorText());
        end else
            Message('%1', GetLastErrorText());
        // if IsReSend and IsSuccess then
        //     Message('Statement journal posted successfully!')
    end;

    procedure GetStmtStatus(var Rec: Record "LSC Posted Statement")
    var
        Item: Record Item;
        APIResult: Text;
        JsonRequestStr: Text;
        llStatus: Boolean;
        lcJournalid: Text;
        lcMovementid: Text;
        PostedStmt: Record "LSC Posted Statement";
        StmtNo: Code[20];
    begin
        Clear(JsonRequestStr);
        Clear(APIResult);
        Clear(RecRef);
        Clear(ErrorMsg);
        CheckConfigInterface();

        RecRef.GetTable(Rec);
        DocumentNo := Rec."No.";
        StmtNo := Rec."No.";
        FunctionsName := 'getStmtStatus';
        JsonRequestStr := StrSubstNo('{company:"%1",statementNo:"%2"}', Company_Name, Rec."No.");
        if CallAPIService_POST(FunctionsName, JsonRequestStr, APIResult, DocumentNo) then begin
            Clear(JSONMgt);
            //JSONMgt.InitializeCollection(APIResult);
            //JSONMgt.GetJsonArray(JArrayData);
            JArrayData.ReadFrom(APIResult);
            foreach JToken in JArrayData do begin
                JObjectData := JToken.AsObject();
                if JObjectData.Get('Status', JToken) then
                    llStatus := JToken.AsValue().AsBoolean();
                if JObjectData.Get('LedgerJournalId', JToken) then
                    lcJournalid := JToken.AsValue().AsText();
                if JObjectData.Get('MovementJournal', JToken) then
                    lcMovementid := JToken.AsValue().AsText();
                if JObjectData.Get('Message', JToken) then
                    ErrorMsg := JToken.AsValue().AsText();
                // foreach JObjectData in JArrayData do begin
                //     EVALUATE(llStatus, FuncCenter.GetValueEnpty(3, FORMAT(JObjectData.GetValue('Status'))));
                //     lcJournalid := FuncCenter.GetValueEnpty(2, FORMAT(JObjectData.GetValue('LedgerJournalId')));
                //     lcMovementid := FuncCenter.GetValueEnpty(2, FORMAT(JObjectData.GetValue('MovementJournal')));
                //     ErrorMsg := FuncCenter.GetValueEnpty(2, FORMAT(JObjectData.GetValue('Message')));
                //if (not llStatus) then begin
                //IF ErrorMsg <> '' then
                //  Message(Text001,ErrorMsg)
                //ELSE
                //  Message('Can Not Create/Update Product.');
                //exit;
                //end;
                if (lcJournalid <> '') OR (lcMovementid <> '') then begin //update posted statement
                    if PostedStmt.Get(StmtNo) then begin
                        if lcJournalid <> '' then
                            PostedStmt."BPC.Journal ID" := lcJournalid;
                        if lcMovementid <> '' then
                            PostedStmt."BPC.Movement ID" := lcMovementid;
                        PostedStmt.MODIFY;
                    end else
                        ERROR('stmt: %1', DocumentNo);
                end;
            end;
        end else
            Message('%1', GetLastErrorText());
    end;

    procedure GetInventTrans()
    var
        APIResult: Text;
        JsonRequestStr: Text;
        RepCounter: Code[20];
        EntryNo: Integer;
        FOInvtTable: Record "BPC.FO - Invent Trans Entries";
        LastRepCode: Code[20];
    begin
        Clear(JsonRequestStr);
        Clear(APIResult);
        Clear(RecRef);
        Clear(ErrorMsg);
        CheckConfigInterface();

        LastRepCode := '000000000';
        FOInvtTable.Reset();
        FOInvtTable.SETCURRENTKEY("BPC.Entry No.");
        if FOInvtTable.FINDLAST then
            LastRepCode := FOInvtTable."BPC.Replication Code";

        FunctionsName := 'getInventTrans';
        JsonRequestStr := StrSubstNo('{company:"%1",repCounter:"%2",repCounterTo:"999999999"}', Company_Name, LastRepCode);
        if CallAPIService_POST(FunctionsName, JsonRequestStr, APIResult, DocumentNo) then begin
            Clear(JSONMgt);
            // JSONMgt.InitializeCollection(APIResult);
            // JSONMgt.GetJsonArray(JArrayData);
            JArrayData.ReadFrom(APIResult);
            foreach JToken in JArrayData do begin
                JObjectData := JToken.AsObject();
                if JObjectData.Get('repCounter', JToken) then
                    RepCounter := JToken.AsValue().AsCode();

                EVALUATE(EntryNo, RepCounter);
                if FOInvtTable.Get(EntryNo) then
                    FOInvtTable.DELETE;
                FOInvtTable.Init();
                FOInvtTable."BPC.Entry No." := EntryNo;
                FOInvtTable."BPC.Replication Code" := RepCounter;
                if JObjectData.Get('datePhysical', JToken) then
                    FOInvtTable."BPC.Physical Date" := JToken.AsValue().AsDate();
                if JObjectData.Get('documentNo', JToken) then
                    FOInvtTable."BPC.Document No." := JToken.AsValue().AsCode();
                if JObjectData.Get('ItemId', JToken) then
                    FOInvtTable."BPC.Item No." := JToken.AsValue().AsCode();
                if JObjectData.Get('ItemName', JToken) then
                    FOInvtTable."BPC.Item Description" := JToken.AsValue().AsText();
                if JObjectData.Get('variant', JToken) then
                    FOInvtTable."BPC.Variant Code" := JToken.AsValue().AsCode();
                if JObjectData.Get('variantName', JToken) then
                    FOInvtTable."BPC.Variant Name" := JToken.AsValue().AsText();
                if JObjectData.Get('qty', JToken) then
                    FOInvtTable."BPC.Quantity" := JToken.AsValue().AsDecimal();
                if JObjectData.Get('warehouse', JToken) then
                    FOInvtTable."BPC.Location Code" := JToken.AsValue().AsCode();
                if JObjectData.Get('serialNo', JToken) then
                    FOInvtTable."BPC.Serial No." := JToken.AsValue().AsCode();
                if JObjectData.Get('batchNo', JToken) then
                    FOInvtTable."BPC.Lot No." := JToken.AsValue().AsCode();
                if JObjectData.Get('batchExpireDate', JToken) then
                    FOInvtTable."BPC.Expiration Date" := JToken.AsValue().AsDate();
                if JObjectData.Get('lotNo', JToken) then
                    FOInvtTable."BPC.Reference Lot No." := JToken.AsValue().AsCode();
                FOInvtTable.Insert();

            end;
        end else
            Message('%1', GetLastErrorText());
    end;

    procedure GetGRNStatus(var Rec: Record "Purch. Rcpt. Header"; HideDialog: Boolean)
    var
        APIResult: Text;
        JsonRequestStr: Text;
        llStatus: Boolean;
        InterfaceDocumentStatus: Record "BPC.Interface Document Status";
        dd: Page "Posted Purchase Rcpt. Subform";
    begin
        Clear(JsonRequestStr);
        Clear(APIResult);
        Clear(RecRef);
        Clear(ErrorMsg);
        CheckConfigInterface();

        RecRef.GetTable(Rec);
        DocumentNo := Rec."No.";
        FunctionsName := 'getGRNStatus';
        JsonRequestStr := StrSubstNo('{company:"%1",warehouse:"%2",pono:"%3",grnno:"%4"}', Company_Name, Rec."LSC Store No.", Rec."Order No.", Rec."No.");
        if CallAPIService_POST(FunctionsName, JsonRequestStr, APIResult, DocumentNo) then begin
            Clear(JSONMgt);
            JArrayData.ReadFrom(APIResult);
            foreach JToken in JArrayData do begin
                JObjectData := JToken.AsObject();
                if JObjectData.Get('Status', JToken) then
                    llStatus := JToken.AsValue().AsBoolean();
                if JObjectData.Get('GRNNo', JToken) then
                    DocumentNo := JToken.AsValue().AsText();
                if JObjectData.Get('Message', JToken) then
                    ErrorMsg := JToken.AsValue().AsText();
                if llStatus then begin
                    if InterfaceDocumentStatus.Get(InterfaceDocumentStatus."BPC.Document Type"::GRN, DocumentNo) then begin
                        InterfaceDocumentStatus."BPC.Posted At FO" := true;
                        InterfaceDocumentStatus.MODIFY;
                    end;
                end;
            end;
        end else begin
            if NOT HideDialog then
                Message('%1', GetLastErrorText());
        end;
    end;

    local procedure "------------Interface------------"()
    begin
    end;

    procedure GenerateTempSalesOrder(IsGenHeader: Boolean; APIResult: Text; SalesHeader: Record "Sales Header")
    var
        StoreLocation: Record "LSC Store Location";
        ItemVariantRegistration: Record "LSC Item Variant Registration";
        VendorNo: Code[20];
        lcVariant: Text;
        MinusQtyFound: Boolean;
        CustomerNo: Text;
        Customer: Record Customer;
        store: Code[20];
        ShipmentMethodCode: Code[20];
        ShipmentMethod: Record "Shipment Method";
        item: Record Item;
        AssemblyLine: Record "Assembly Line";
        AssemblyHeader: Record "Assembly Header";
        AssembletoOrderLink: Record "Assemble-to-Order Link";
        CheckAssembletoOrderLink: Record "Assemble-to-Order Link";
        JSUnitConArray: JsonArray;
        JUnitCon: JsonToken;
        JUnitConOJ: JsonObject;
        JTypeToken: JsonToken;
        bomLineNo: Integer;
        Lot: Code[20];
        Serial: Code[20];
        bomItemNo: Code[20];
        bomQuantity: Decimal;
        ReservationEntry: Record "Reservation Entry";
        CustomerName: Text;
        RequestedShipDate: DateTime;
        RequestedReceiptDate: DateTime;
        LSCPOSDataEntry: Record "LSC POS Data Entry";
        POSApplEntry: Record "LSC POS Data Entry";
        LSCVoucherEntries: Record "LSC Voucher Entries";
        VoucherEntries: Record "LSC Voucher Entries";
        DepositInvoiceNo: Text;
        DepositCurrency: Text;
        DepositInvoiceAmount: Decimal;
        LSCRetailUser: Record "LSC Retail User";
        ShiptoAddress: Text;
        ShiptoAddress2: Text;
        Position: Integer;
        Length: Integer;
        SalesShipmentHeader: Record "Sales Shipment Header";
        countline: Integer;
        maxcountline: Integer;
        lineno: Integer;
        lineno1: Integer;
        InsertSalesLine: Boolean;
        LineDiscountAmount: Decimal;
        Amount: Decimal;
        OutstandingQuantity: Decimal;
        PostedCustOrder: Record "LSC Posted CO Header";
        SalesShipment: Record "Sales Shipment Header";
        pItem: Record Item;
        Branch: Text[5];
        HeaderOffice: Boolean;
        HeaderOfficeText: Text;
        TItem: Record Item;
        ChekhSalesHeader: Record "Sales Header";
        StatusSO: Text;
    begin
        TempSalesHeader.DeleteAll();
        TempSalesLine.DeleteAll();
        TempSalesLine1.DeleteAll();
        TempSalesLine2.DeleteAll();
        MinusQtyFound := FALSE;
        Clear(JSONMgt);
        Clear(JObjectData);
        Clear(JArrayData);
        Clear(CustomerNo);
        Clear(store);
        Clear(ShipmentMethodCode);
        Clear(JSUnitConArray);
        Clear(JUnitConOJ);
        Clear(JTypeToken);
        Clear(JUnitCon);
        Clear(Lot);
        Clear(Serial);
        Clear(CustomerName);
        Clear(DepositInvoiceNo);
        Clear(DepositCurrency);
        Clear(DepositInvoiceAmount);
        Clear(ShiptoAddress);
        Clear(ShiptoAddress2);
        Clear(Position);
        Clear(Length);
        Clear(lineno);
        Clear(Branch);
        Clear(HeaderOffice);
        Clear(HeaderOfficeText);
        Clear(StatusSO);
        Window.OPEN('Generate Sales No. #1############################');
        JArrayData.ReadFrom(APIResult);
        foreach JToken in JArrayData do begin
            JObjectData := JToken.AsObject();
            if IsGenHeader then begin
                TempSalesHeader.Init();
                if JObjectData.Get('SalesOrder', JToken) then
                    TempSalesHeader."No." := JToken.AsValue().AsCode();
                // ChekhSalesHeader.Reset(); Joe 2025/02--
                // ChekhSalesHeader.SetRange(ChekhSalesHeader."Document Type", ChekhSalesHeader."Document Type"::Order); Joe 2025/02--
                // ChekhSalesHeader.SetRange("No.", TempSalesHeader."No."); Joe 2025/02--
                // if not ChekhSalesHeader.FindSet() then begin Joe 2025/02--
                PostedCustOrder.Reset();
                PostedCustOrder.SetRange("Document ID", TempSalesHeader."No.");
                if not PostedCustOrder.FindFirst() then begin
                    SalesShipment.Reset();
                    SalesShipment.SetRange("Order No.", TempSalesHeader."No.");
                    if not SalesShipment.FindSet() then begin
                        TempSalesHeader."Document Type" := TempSalesHeader."Document Type"::Order;
                        if JObjectData.Get('CustomerName', JToken) then
                            CustomerName := JToken.AsValue().AsText();
                        if JObjectData.Get('CustomerAccount', JToken) then begin
                            CustomerNo := JToken.AsValue().AsCode();
                            TempSalesHeader."Sell-to Customer No." := CustomerNo;
                        end;
                        if JObjectData.Get('Branch', JToken) then
                            Branch := JToken.AsValue().AsText();
                        if JObjectData.Get('HeaderOffice', JToken) then begin
                            HeaderOfficeText := JToken.AsValue().AsText();
                            if HeaderOfficeText = 'Yes' then
                                HeaderOffice := true
                            else
                                HeaderOffice := false;
                        end;
                        TempSalesHeader."Sell-to Customer Name" := CustomerName;
                        if JObjectData.Get('Warehouse', JToken) then begin
                            store := JToken.AsValue().AsCode();
                            TempSalesHeader."Location Code" := store;
                            TempSalesHeader."BPC.Location Code" := store;
                        end;
                        StoreLocation.Reset();
                        StoreLocation.SetRange("Location Code", TempSalesHeader."Location Code");
                        if StoreLocation.FindSet() then
                            TempSalesHeader."LSC Store No." := StoreLocation."Store No.";
                        if JObjectData.Get('SalesTaxGroup', JToken) then
                            TempSalesHeader."VAT Bus. Posting Group" := JToken.AsValue().AsCode();

                        if JObjectData.Get('PlatformOrder', JToken) then
                            if JToken.AsValue().AsText() <> '' then
                                TempSalesHeader."BPC.Reference Online Order" := JToken.AsValue().AsText();

                        if JObjectData.Get('CustomerReference', JToken) then
                            if JToken.AsValue().AsText() <> '' then
                                TempSalesHeader."BPC.Reference Online Order" := JToken.AsValue().AsText();

                        // if JObjectData.Get('PricesIncludeSalesTax', JToken) then
                        //     TempSalesHeader."Prices Including VAT" := JToken.AsValue().AsBoolean();
                        TempSalesHeader."Prices Including VAT" := true;
                        TempSalesHeader."Ship-to Code" := CopyStr(CustomerNo, 1, 10);
                        if JObjectData.Get('DeliveryAddress', JToken) then begin
                            ShiptoAddress := JToken.AsValue().AsText();
                            TempSalesHeader."Ship-to Address" := CopyStr(ShiptoAddress, 1, 100);
                        end;
                        if JObjectData.Get('DeliveryAddress2', JToken) then begin
                            ShiptoAddress2 := JToken.AsValue().AsText();
                            TempSalesHeader."Ship-to Address 2" := CopyStr(ShiptoAddress2, 1, 50);
                        end;
                        if JObjectData.Get('DeliveryPostalCode', JToken) then
                            TempSalesHeader."Ship-to Post Code" := JToken.AsValue().AsText();
                        if JObjectData.Get('DeliveryCity', JToken) then
                            TempSalesHeader."Ship-to City" := JToken.AsValue().AsText();
                        if JObjectData.Get('DeliveryCountry', JToken) then
                            TempSalesHeader."Ship-to Country/Region Code" := JToken.AsValue().AsText();
                        if TempSalesHeader."Ship-to Country/Region Code" = 'THA' then
                            TempSalesHeader."Ship-to Country/Region Code" := 'TH';
                        if JObjectData.Get('DeliveryName', JToken) then
                            TempSalesHeader."Ship-to Name" := JToken.AsValue().AsText();
                        TempSalesHeader."Bill-to Customer No." := CustomerNo;
                        if JObjectData.Get('InvoiceName', JToken) then
                            TempSalesHeader."Bill-to Name" := JToken.AsValue().AsText();
                        if JObjectData.Get('InvoiceAddress', JToken) then
                            TempSalesHeader."Bill-to Address" := CopyStr(JToken.AsValue().AsText(), 1, 100);
                        if JObjectData.Get('InvoiceAddress2', JToken) then
                            TempSalesHeader."Bill-to Address 2" := CopyStr(JToken.AsValue().AsText(), 1, 50);
                        if JObjectData.Get('InvoicePostalCode', JToken) then
                            TempSalesHeader."Bill-to Post Code" := JToken.AsValue().AsText();
                        if JObjectData.Get('InvoiceCity', JToken) then
                            TempSalesHeader."Bill-to City" := JToken.AsValue().AsText();
                        if JObjectData.Get('InvoiceCountry', JToken) then
                            TempSalesHeader."Bill-to Country/Region Code" := JToken.AsValue().AsText();
                        if TempSalesHeader."Bill-to Country/Region Code" = 'THA' then
                            TempSalesHeader."Bill-to Country/Region Code" := 'TH';
                        TempSalesHeader."Sell-to Address" := CopyStr(TempSalesHeader."Bill-to Address", 1, 100);
                        TempSalesHeader."Sell-to Address 2" := CopyStr(TempSalesHeader."Bill-to Address 2", 1, 50);
                        TempSalesHeader."Sell-to Post Code" := TempSalesHeader."Bill-to Post Code";
                        TempSalesHeader."Sell-to City" := TempSalesHeader."Bill-to City";
                        TempSalesHeader."Sell-to Country/Region Code" := TempSalesHeader."Bill-to Country/Region Code";

                        if JObjectData.Get('InvoiceRegistrationID', JToken) then
                            TempSalesHeader."VAT Registration No." := JToken.AsValue().AsText();
                        if JObjectData.Get('TotalDiscount', JToken) then
                            TempSalesHeader."Invoice Discount Value" := JToken.AsValue().AsDecimal();
                        if JObjectData.Get('ModeOfDelivery', JToken) then begin
                            ShipmentMethodCode := JToken.AsValue().AsCode();
                            if ShipmentMethodCode <> '' then begin
                                if not ShipmentMethod.Get(ShipmentMethodCode) then begin
                                    ShipmentMethod.Init();
                                    ShipmentMethod.Code := ShipmentMethodCode;
                                    ShipmentMethod.Insert();
                                end;
                                TempSalesHeader."Shipment Method Code" := ShipmentMethodCode;
                            end;
                        end;

                        if JObjectData.Get('RequestedShipDate', JToken) then begin
                            RequestedShipDate := JToken.AsValue().AsDateTime();
                            TempSalesHeader."Shipment Date" := DT2Date(RequestedShipDate);
                        end;

                        if JObjectData.Get('RequestedReceiptDate', JToken) then begin
                            RequestedReceiptDate := JToken.AsValue().AsDateTime();
                            TempSalesHeader."Requested Delivery Date" := DT2Date(RequestedReceiptDate);
                        end;

                        if JObjectData.Get('DepositInvoiceNo', JToken) then
                            DepositInvoiceNo := JToken.AsValue().AsText();

                        if JObjectData.Get('DepositCurrency', JToken) then
                            DepositCurrency := JToken.AsValue().AsText();

                        if JObjectData.Get('DepositInvoiceAmount', JToken) then
                            DepositInvoiceAmount := JToken.AsValue().AsDecimal();

                        if DepositInvoiceNo <> '' then begin

                            if not LSCRetailUser.Get(UserId()) then
                                LSCRetailUser.Init();

                            LSCPOSDataEntry.Reset();
                            LSCPOSDataEntry.SetRange("Entry Code", CopyStr(DepositInvoiceNo, 1, 20));
                            LSCPOSDataEntry.SetRange("Entry Type", 'DEPOSIT');
                            if not LSCPOSDataEntry.FindSet() then begin
                                LSCPOSDataEntry.Init();
                                LSCPOSDataEntry."Entry Code" := CopyStr(DepositInvoiceNo, 1, 20);
                                LSCPOSDataEntry."Entry Type" := 'DEPOSIT';
                                LSCPOSDataEntry."Currency Code" := CopyStr(DepositCurrency, 1, 10);
                                LSCPOSDataEntry."Created in Store No." := LSCRetailUser."Store No.";
                                LSCPOSDataEntry."Date Created" := Today();
                                LSCPOSDataEntry."Created by Receipt No." := TempSalesHeader."No.";
                                POSApplEntry.Reset();
                                POSApplEntry.SetCurrentKey("Replication Counter");
                                if POSApplEntry.FindLast() then
                                    LSCPOSDataEntry."Replication Counter" := POSApplEntry."Replication Counter" + 1
                                else
                                    LSCPOSDataEntry."Replication Counter" := 1;

                                LSCPOSDataEntry.Validate(Amount, DepositInvoiceAmount);
                                LSCPOSDataEntry.Insert();
                            end else begin
                                LSCPOSDataEntry."Currency Code" := CopyStr(DepositCurrency, 1, 10);
                                LSCPOSDataEntry."Created in Store No." := LSCRetailUser."Store No.";
                                LSCPOSDataEntry."Created by Receipt No." := TempSalesHeader."No.";
                                LSCPOSDataEntry.Validate(Amount, DepositInvoiceAmount);
                                LSCPOSDataEntry."Entry Type" := 'DEPOSIT';
                                LSCPOSDataEntry.Modify();
                            end;

                            LSCVoucherEntries.SetRange("Receipt Number", TempSalesHeader."No.");
                            //LSCVoucherEntries.SetRange("Voucher No.", DepositInvoiceNo);
                            LSCVoucherEntries.SetRange("Store No.", LSCRetailUser."Store No.");
                            if not LSCVoucherEntries.FindSet() then begin
                                LSCVoucherEntries."Receipt Number" := TempSalesHeader."No.";
                                LSCVoucherEntries."Line No." := 10000;
                                LSCVoucherEntries."POS Terminal No." := '0000';
                                LSCVoucherEntries."Transaction No." := 0;
                                LSCVoucherEntries."Store No." := LSCRetailUser."Store No.";
                                LSCVoucherEntries."Voucher No." := CopyStr(DepositInvoiceNo, 1, 20);
                                LSCVoucherEntries.Amount := DepositInvoiceAmount;
                                LSCVoucherEntries."Voucher Type" := 'DEPOSIT';
                                LSCVoucherEntries."Currency Code" := CopyStr(DepositCurrency, 1, 10);
                                LSCVoucherEntries."Store Currency Code" := CopyStr(DepositCurrency, 1, 10);
                                VoucherEntries.Reset();
                                VoucherEntries.SetCurrentKey("Replication Counter");
                                if VoucherEntries.FindLast() then
                                    LSCVoucherEntries."Replication Counter" := VoucherEntries."Replication Counter" + 1
                                else
                                    LSCVoucherEntries."Replication Counter" := 1;
                                LSCVoucherEntries.Date := Today();
                                LSCVoucherEntries.Time := Time();
                                LSCVoucherEntries.Insert();
                            end else begin
                                LSCVoucherEntries."Currency Code" := CopyStr(DepositCurrency, 1, 10);
                                LSCVoucherEntries."Store Currency Code" := CopyStr(DepositCurrency, 1, 10);
                                LSCVoucherEntries.Amount := DepositInvoiceAmount;
                                LSCVoucherEntries."Voucher Type" := 'DEPOSIT';
                                LSCVoucherEntries.Modify();
                            end;

                        end;
                        // if TempSalesHeader."No." = 'SOS123-00315' then
                        //     Message('ETST');
                        InsertCustomer(TempSalesHeader, HeaderOffice, Branch);
                        //TempSalesHeader.Status := TempSalesHeader.Status::Released;
                        if JObjectData.Get('Status', JToken) then
                            StatusSO := JToken.AsValue().AsText();
                        if StatusSO = 'Canceled' then
                            TempSalesHeader.Status := TempSalesHeader.Status::Cancel;
                        TempSalesHeader."BPC.Interface" := true;
                        TempSalesHeader."BPC.Active" := true;
                        TempSalesHeader.Insert();
                    end;
                end;
                // end; Joe 2025/02--
            end else begin
                TempSalesLine.Init();
                TempSalesLine."Document Type" := SalesHeader."Document Type";
                TempSalesLine."Document No." := SalesHeader."No.";
                TempSalesLine."Sell-to Customer No." := SalesHeader."Sell-to Customer No.";
                lineno := lineno + 10000;

                // Joe 2025/03/13 ++
                if JObjectData.Get('LineNumber', JToken) then
                    lineno := JToken.AsValue().AsDecimal() * 10000;
                // Joe 2025/03/13 --

                TempSalesLine."Line No." := lineno;
                TempSalesLine.Type := TempSalesLine.Type::Item;
                if JObjectData.Get('ItemNumber', JToken) then
                    TempSalesLine."No." := CopyStr(JToken.AsValue().AsCode(), 1, 20);
                if JObjectData.Get('ProductName', JToken) then
                    TempSalesLine.Description := CopyStr(JToken.AsValue().AsText(), 1, 100);
                TempSalesLine."Location Code" := SalesHeader."Location Code";
                if TempSalesLine."Location Code" <> SalesHeader."Location Code" then
                    Message('Location %1 not found in store %2', TempSalesLine."Location Code", SalesHeader."Location Code");

                if JObjectData.Get('Quantity', JToken) then
                    TempSalesLine.Quantity := JToken.AsValue().AsDecimal();

                if not item.Get(TempSalesLine."No.") then
                    item.Init();

                if TempSalesLine.Quantity <> 0 then
                    if item."Assembly BOM" then
                        TempSalesLine."Qty. to Assemble to Order" := TempSalesLine.Quantity;

                if JObjectData.Get('UnitPrice', JToken) then
                    TempSalesLine."Unit Price" := JToken.AsValue().AsDecimal();
                if JObjectData.Get('Unit', JToken) then
                    TempSalesLine."Unit of Measure Code" := CopyStr(JToken.AsValue().AsCode(), 1, 10);
                if JObjectData.Get('VATPercent', JToken) then
                    TempSalesLine."VAT %" := JToken.AsValue().AsDecimal();
                if JObjectData.Get('TotalLineDiscount', JToken) then
                    TempSalesLine."Line Discount Amount" := JToken.AsValue().AsDecimal();
                if JObjectData.Get('NetAmount', JToken) then
                    TempSalesLine.Amount := JToken.AsValue().AsDecimal();
                if JObjectData.Get('RemainQuantity', JToken) then
                    TempSalesLine."Outstanding Quantity" := JToken.AsValue().AsDecimal();
                if JObjectData.Get('Warehouse', JToken) then
                    TempSalesLine."Location Code" := CopyStr(JToken.AsValue().AsCode(), 1, 10);
                if JObjectData.Get('UnitPrice', JToken) then
                    TempSalesLine."Unit Price" := JToken.AsValue().AsDecimal();
                if JObjectData.Get('BatchNumber', JToken) then
                    Lot := CopyStr(JToken.AsValue().AsCode(), 1, 20);
                if JObjectData.Get('SerialNumber', JToken) then
                    Serial := CopyStr(JToken.AsValue().AsCode(), 1, 20);
                if (Lot <> '') or (Serial <> '') then begin
                    ReservationEntry.Reset();
                    ReservationEntry.SetRange("Item No.", TempSalesLine."No.");
                    ReservationEntry.SetRange("Source ID", TempSalesLine."Document No.");
                    ReservationEntry.SetRange("Source Type", 37);
                    ReservationEntry.SetRange("Source Subtype", 1);
                    ReservationEntry.SetRange("Source Ref. No.", TempSalesLine."Line No.");
                    if not ReservationEntry.FindSet() then begin
                        ReservationEntry.init();
                        // ReservationEntry."Entry No." := ReservationEntry.GetLastEntryNo();
                        ReservationEntry."Entry No." := GetLastEntry();
                        ReservationEntry."Source Type" := 37;
                        ReservationEntry."Source ID" := TempSalesLine."Document No.";
                        ReservationEntry."Item No." := TempSalesLine."No.";
                        ReservationEntry."Source Subtype" := 1;
                        ReservationEntry."Source Ref. No." := TempSalesLine."Line No.";
                        ReservationEntry.Positive := true;
                        ReservationEntry."Reservation Status" := ReservEntry."Reservation Status"::Surplus;
                        ReservationEntry."Created By" := CopyStr(UserId(), 1, 50);
                        ReservationEntry."Creation Date" := Today();
                        ReservationEntry."Variant Code" := TempSalesLine."Variant Code";
                        ReservationEntry."Location Code" := TempSalesLine."Location Code";
                        ReservationEntry.Quantity := TempSalesLine.Quantity;
                        ReservationEntry."Qty. per Unit of Measure" := TempSalesLine."Qty. per Unit of Measure";
                        ReservationEntry."Quantity (Base)" := TempSalesLine."Quantity (Base)";
                        ReservationEntry."Qty. to Handle (Base)" := TempSalesLine."Quantity (Base)";
                        ReservationEntry."Qty. to Invoice (Base)" := TempSalesLine."Quantity (Base)";
                        ReservationEntry."Lot No." := Lot;
                        ReservationEntry."Serial No." := Serial;
                        if Lot <> '' then
                            ReservationEntry."Item Tracking" := ReservationEntry."Item Tracking"::"Lot No.";
                        if Serial <> '' then
                            ReservationEntry."Item Tracking" := ReservationEntry."Item Tracking"::"Serial No.";
                        ReservationEntry.Insert();
                    end else begin
                        ReservationEntry.Init();
                        ReservationEntry.Positive := true;
                        ReservationEntry."Reservation Status" := ReservEntry."Reservation Status"::Surplus;
                        ReservationEntry."Created By" := CopyStr(UserId(), 1, 50);
                        ReservationEntry."Creation Date" := Today();
                        ReservationEntry."Variant Code" := TempSalesLine."Variant Code";
                        ReservationEntry."Location Code" := TempSalesLine."Location Code";
                        ReservationEntry.Quantity := 1;
                        ReservationEntry."Qty. per Unit of Measure" := TempSalesLine."Qty. per Unit of Measure";
                        ReservationEntry."Quantity (Base)" := TempSalesLine."Quantity (Base)";
                        ReservationEntry."Qty. to Handle (Base)" := TempSalesLine."Quantity (Base)";
                        ReservationEntry."Qty. to Invoice (Base)" := TempSalesLine."Quantity (Base)";
                        ReservationEntry."Lot No." := Lot;
                        ReservationEntry."Serial No." := Serial;
                        if Lot <> '' then
                            ReservationEntry."Item Tracking" := ReservationEntry."Item Tracking"::"Lot No.";
                        if Serial <> '' then
                            ReservationEntry."Item Tracking" := ReservationEntry."Item Tracking"::"Serial No.";
                        ReservationEntry.Modify()
                    end;
                end;
                TempSalesLine."BPC.Not Check AutoAsmToOrder" := false;
                Clear(bomLineNo);
                Clear(bomItemNo);
                Clear(bomQuantity);
                if JObjectData.Get('BOM', JToken) then begin
                    JSUnitConArray := JToken.AsArray();
                    TMPAssemblyLine.DeleteAll();
                    TMPAssemblyHeader.DeleteAll();
                    TMPAssembletoOrderLink.DeleteAll();
                    foreach JUnitCon in JSUnitConArray do begin
                        JUnitConOJ := JUnitCon.AsObject();
                        if JUnitConOJ.Get('bomLineNo', JTypeToken) then
                            bomLineNo := JTypeToken.AsValue().AsInteger();

                        if JUnitConOJ.Get('bomItemNo', JTypeToken) then
                            bomItemNo := CopyStr(JTypeToken.AsValue().AsCode(), 1, 20);

                        if JUnitConOJ.Get('bomQuantity', JTypeToken) then
                            bomQuantity := JTypeToken.AsValue().AsDecimal();

                        // insertAssembly BOM
                        if bomItemNo <> '' then
                            if item."Item Tracking Code" = 'SERIAL' then begin
                                //++ แยก line
                                if TempSalesLine.Quantity <= 1 then begin
                                    TempSalesLine."Qty. to Assemble to Order" := TempSalesLine.Quantity;
                                    TempSalesLine."Qty. to Asm. to Order (Base)" := TempSalesLine.Quantity;
                                    TempSalesLine."BPC.Not Check AutoAsmToOrder" := true;
                                    INSERTAssemblyBOM(TempSalesLine, bomLineNo, bomItemNo, bomQuantity);
                                end else begin
                                    TempSalesLine."Qty. to Assemble to Order" := 1;
                                    TempSalesLine."Qty. to Asm. to Order (Base)" := 1;
                                    TempSalesLine."BPC.Not Check AutoAsmToOrder" := true;
                                    //INSERTAssemblyBOM(TempSalesLine, bomLineNo, bomItemNo, bomQuantity);
                                    INSERT_TMPAssemblyBOM(TempSalesLine, bomLineNo, bomItemNo, bomQuantity);
                                end;
                                //-- แยก line
                            end else begin
                                TempSalesLine."Qty. to Assemble to Order" := TempSalesLine.Quantity;
                                TempSalesLine."Qty. to Asm. to Order (Base)" := TempSalesLine.Quantity;
                                TempSalesLine."BPC.Not Check AutoAsmToOrder" := true;
                                INSERTAssemblyBOM(TempSalesLine, bomLineNo, bomItemNo, bomQuantity);
                            end;

                    end;
                end;
                Clear(countline);
                InsertSalesLine := true;
                //Tar 19/02/2024++ แยก line
                if item."Item Tracking Code" = 'SERIAL' then
                    if (bomItemNo <> '') and (TempSalesLine.Quantity > 1) then begin
                        Clear(maxcountline);
                        Clear(LineDiscountAmount);
                        Clear(Amount);
                        Clear(OutstandingQuantity);
                        Clear(lineno);
                        maxcountline := TempSalesLine.Quantity;
                        LineDiscountAmount := TempSalesLine."Line Discount Amount" / TempSalesLine.Quantity;
                        Amount := TempSalesLine.Amount / TempSalesLine.Quantity;
                        OutstandingQuantity := TempSalesLine."Outstanding Quantity" / TempSalesLine.Quantity;
                        repeat
                            countline += 1;
                            TempSalesLine1.Init();
                            TempSalesLine1."Document Type" := SalesHeader."Document Type";
                            TempSalesLine1."Document No." := SalesHeader."No.";
                            if countline = 1 then begin
                                TempSalesLine1."Line No." := TempSalesLine."Line No.";
                                lineno := TempSalesLine."Line No."
                            end else begin
                                TempSalesLine1."Line No." := lineno + 10000;
                                lineno := lineno + 10000;
                            end;
                            TempSalesLine1."Sell-to Customer No." := SalesHeader."Sell-to Customer No.";

                            TempSalesLine1.Type := TempSalesLine1.Type::Item;
                            TempSalesLine1."No." := TempSalesLine."No.";
                            TempSalesLine1.Description := TempSalesLine.Description;
                            TempSalesLine1."Location Code" := TempSalesLine."Location Code";
                            TempSalesLine1.Quantity := 1;
                            TempSalesLine1."Unit of Measure Code" := TempSalesLine."Unit of Measure Code";
                            TempSalesLine1."Unit Price" := TempSalesLine."Unit Price";
                            TempSalesLine1."Line Discount Amount" := LineDiscountAmount;
                            TempSalesLine1.Amount := Amount;
                            TempSalesLine1."Outstanding Quantity" := 1;

                            TempSalesLine1."Qty. to Assemble to Order" := 1;
                            TempSalesLine1."Qty. to Asm. to Order (Base)" := 1;
                            TempSalesLine1."BPC.Not Check AutoAsmToOrder" := true;
                            INSERT_AssemblyBOM(TempSalesLine1);

                            TempSalesLine1."BPC.Interface" := true;
                            TempSalesLine1."BPC.Active" := true;
                            if TempSalesLine1."Outstanding Quantity" = 0 then
                                TempSalesLine1."BPC.Active" := FALSE;
                            TempSalesLine.TransferFields(TempSalesLine1);
                            TempSalesLine.Insert();
                        until countline = maxcountline;
                        InsertSalesLine := false;
                    end;

                //Tar 19/02/2024-- แยก line

                TempSalesLine."BPC.Interface" := true;
                TempSalesLine."BPC.Active" := true;
                if TempSalesLine."Outstanding Quantity" = 0 then
                    TempSalesLine."BPC.Active" := FALSE;
                if InsertSalesLine then
                    TempSalesLine.Insert();
                if MinusQtyFound AND (TempSalesLine.Quantity < 0) then
                    MinusQtyFound := true;
            end;
        end;

        Window.Close();
    end;

    procedure InsertCustomer(SalesHeader: Record "Sales Header" temporary; HeaderOffice: Boolean; Branch: text[5])
    var
        Customer: Record Customer;
        CustomerTempl: Record "Customer Templ.";
        PostCode: Record "Post Code";
        ShipAddress: Record "Ship-to Address";
        SalesShipmentHeader: Record "Sales Shipment Header";
        CountryRegion: Record "Country/Region";
        CustomerNo: Text;
    begin
        PostCode.Reset();
        SalesShipmentHeader.Reset();
        SalesShipmentHeader.SetRange("Order No.", SalesHeader."No.");
        if SalesShipmentHeader.IsEmpty() then begin
            if not Customer.Get(SalesHeader."Sell-to Customer No.") then begin
                Customer.Init();
                Customer."No." := SalesHeader."Sell-to Customer No.";
                Customer.Name := SalesHeader."Sell-to Customer Name";
                Customer."Search Name" := SalesHeader."Sell-to Customer Name";
                if CustomerTempl.Get('DEFAULT') then begin
                    Customer."Gen. Bus. Posting Group" := CustomerTempl."Gen. Bus. Posting Group";
                    Customer."VAT Bus. Posting Group" := CustomerTempl."VAT Bus. Posting Group";
                    Customer."Customer Posting Group" := CustomerTempl."Customer Posting Group";
                    Customer."Payment Method Code" := CustomerTempl."Payment Method Code";
                    Customer."Prices Including VAT" := CustomerTempl."Prices Including VAT";
                    Customer."Payment Terms Code" := CustomerTempl."Payment Terms Code";
                end;
                Customer."BPC Branch No." := Branch;
                Customer."BPC Head Office" := HeaderOffice;
                //if not Customer."BPC.API Update Customer" then begin
                CountryRegion.Reset();
                CountryRegion.SetRange(Code, SalesHeader."Sell-to Country/Region Code");
                if not CountryRegion.FindSet() then begin
                    CountryRegion.Code := SalesHeader."Sell-to Country/Region Code";
                    CountryRegion.Insert();
                end;

                if (SalesHeader."Sell-to Post Code" <> '') and (SalesHeader."Sell-to City" <> '') then begin
                    PostCode.Reset();
                    PostCode.SetRange(Code, SalesHeader."Sell-to Post Code");
                    if not PostCode.FindSet() then begin
                        PostCode.Init();
                        PostCode.Code := SalesHeader."Sell-to Post Code";
                        PostCode.City := SalesHeader."Sell-to City";
                        PostCode."Country/Region Code" := SalesHeader."Sell-to Country/Region Code";
                        PostCode.Insert();
                    end;
                end;

                CustomerNo := SalesHeader."Sell-to Customer No.";
                if CopyStr(CustomerNo, 1, 2) = 'E-' then
                    Customer."BPC.API not Update Customer" := true
                else begin
                    Customer.Address := SalesHeader."Sell-to Address";
                    Customer."Address 2" := SalesHeader."Sell-to Address 2";
                    Customer.Validate("Post Code", SalesHeader."Sell-to Post Code");
                    Customer.Validate("Country/Region Code", SalesHeader."Sell-to Country/Region Code");
                end;
                //end;
                Customer.Insert();

            end
            else
                if not Customer."BPC.API not Update Customer" then begin
                    Customer.Name := SalesHeader."Sell-to Customer Name";
                    Customer."Search Name" := SalesHeader."Sell-to Customer Name";
                    Customer."BPC Branch No." := Branch;
                    Customer."BPC Head Office" := HeaderOffice;
                    CountryRegion.Reset();
                    CountryRegion.SetRange(Code, SalesHeader."Sell-to Country/Region Code");
                    if CountryRegion.IsEmpty() then
                        CountryRegion.Code := SalesHeader."Sell-to Country/Region Code";

                    if (SalesHeader."Sell-to Post Code" <> '') and (SalesHeader."Sell-to City" <> '') then
                        if not PostCode.Get(SalesHeader."Sell-to Post Code", SalesHeader."Sell-to City") then begin
                            PostCode.Init();
                            PostCode.Code := SalesHeader."Sell-to Post Code";
                            PostCode.City := SalesHeader."Sell-to City";
                            PostCode."Country/Region Code" := SalesHeader."Sell-to Country/Region Code";
                            PostCode.Insert();
                        end;

                    Customer.Address := SalesHeader."Sell-to Address";
                    Customer."Address 2" := SalesHeader."Sell-to Address 2";
                    Customer."Post Code" := SalesHeader."Sell-to Post Code";
                    Customer."Country/Region Code" := SalesHeader."Sell-to Country/Region Code";
                    Customer.Modify();
                end;

            ShipAddress.Reset();
            if not ShipAddress.Get(SalesHeader."Sell-to Customer No.", SalesHeader."Ship-to Code") then begin
                ShipAddress.Init();
                ShipAddress."Customer No." := SalesHeader."Sell-to Customer No.";
                ShipAddress.Code := SalesHeader."Ship-to Code";
                ShipAddress.Name := SalesHeader."Ship-to Name";
                ShipAddress.Address := SalesHeader."Ship-to Address";
                ShipAddress."Address 2" := SalesHeader."Ship-to Address 2";

                if (SalesHeader."Ship-to Post Code" <> '') and (SalesHeader."Ship-to City" <> '') then begin
                    if not PostCode.Get(SalesHeader."Ship-to Post Code", SalesHeader."Ship-to City") then begin
                        PostCode.Init();
                        PostCode.Code := SalesHeader."Ship-to Post Code";
                        PostCode.City := SalesHeader."Ship-to City";
                        PostCode."Country/Region Code" := SalesHeader."Ship-to Country/Region Code";
                        PostCode.Insert();
                    end;
                    ShipAddress.Validate("Post Code", SalesHeader."Ship-to Post Code");
                end;
                ShipAddress.Insert();
                // end else begin
                //     ShipAddress.Name := SalesHeader."Ship-to Name";
                //     ShipAddress.Address := SalesHeader."Ship-to Address";
                //     ShipAddress."Address 2" := SalesHeader."Ship-to Address 2";

                //     if (SalesHeader."Ship-to Post Code" <> '') and (SalesHeader."Ship-to City" <> '') then begin
                //         if not PostCode.Get(SalesHeader."Ship-to Post Code", SalesHeader."Ship-to City") then begin
                //             PostCode.Init();
                //             PostCode.Code := SalesHeader."Ship-to Post Code";
                //             PostCode.City := SalesHeader."Ship-to City";
                //             PostCode."Country/Region Code" := SalesHeader."Ship-to Country/Region Code";
                //             PostCode.Insert();
                //         end;
                //         ShipAddress.Validate("Post Code", SalesHeader."Ship-to Post Code");
                //     end;
                //     ShipAddress.Modify();
            end;
            Commit();
        end;
    end;

    local procedure INSERTAssemblyBOM(Tmpsalesline: Record "Sales Line" temporary; bomLineNo: Integer; bomItemNo: Code[20]; bomQuantity: Decimal)
    var
        AssemblyLine: Record "Assembly Line";
        AssemblyHeader: Record "Assembly Header";
        AssembletoOrderLink: Record "Assemble-to-Order Link";
        CheckAssembletoOrderLink: Record "Assemble-to-Order Link";
        AssemblySetup: Record "Assembly Setup";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        OldNoSeriesCode: code[20];
        NewDate: date;
        NewNo: code[20];
        OldNo: code[20];
        NewNoSeriesCode: code[20];
    begin
        Clear(OldNoSeriesCode);
        Clear(NewDate);
        Clear(NewNo);
        Clear(OldNo);
        AssemblySetup.Get();
        CheckAssembletoOrderLink.Reset();
        CheckAssembletoOrderLink.SetRange("Assembly Document Type", AssembletoOrderLink."Assembly Document Type"::Order);
        CheckAssembletoOrderLink.SetRange("Document No.", Tmpsalesline."Document No.");
        CheckAssembletoOrderLink.SetRange("Document Type", AssembletoOrderLink."Document Type"::Order);
        CheckAssembletoOrderLink.SetRange("Document Line No.", Tmpsalesline."Line No.");
        if not CheckAssembletoOrderLink.FindFirst() then begin
            NoSeriesMgt.InitSeries(AssemblySetup."Assembly Order Nos.", OldNoSeriesCode, NewDate, NewNo, NewNoSeriesCode);

            AssemblyHeader.Reset();
            AssemblyHeader.SetRange("No.", NewNo);
            AssemblyHeader.SetRange("Document Type", AssemblyHeader."Document Type"::Order);
            if not AssemblyHeader.FindSet() then begin
                AssemblyHeader.Init();
                AssemblyHeader."No." := NewNo;
                AssemblyHeader."Document Type" := AssemblyHeader."Document Type"::Order;
                AssemblyHeader."Posting Date" := WorkDate();
                AssemblyHeader."Due Date" := WorkDate();
                AssemblyHeader."Starting Date" := WorkDate();
                AssemblyHeader."Ending Date" := WorkDate();
                AssemblyHeader.Validate("Item No.", Tmpsalesline."No.");
                AssemblyHeader.Validate(Quantity, Tmpsalesline.Quantity);
                AssemblyHeader.Validate("Location Code", Tmpsalesline."Location Code");
                AssemblyHeader."No. Series" := AssemblySetup."Assembly Order Nos.";
                AssemblyHeader."Posting No. Series" := AssemblySetup."Posted Assembly Order Nos.";
                AssemblyHeader.Status := AssemblyHeader.Status::Open;
                AssemblyHeader.Insert();
            end;
            bomLineNo := bomLineNo * 10000;
            AssemblyLine.Reset();
            AssemblyLine.SetRange("Document No.", NewNo);
            AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
            AssemblyLine.SetRange("Line No.", bomLineNo);
            if not AssemblyLine.FindSet() then begin
                AssemblyLine.Init();
                AssemblyLine."Document No." := NewNo;
                AssemblyLine."Document Type" := AssemblyLine."Document Type"::Order;
                AssemblyLine."Line No." := bomLineNo;
                AssemblyLine.Validate(Type, AssemblyLine.Type::Item);
                AssemblyLine.Validate("No.", bomItemNo);
                AssemblyLine.Validate("Location Code", AssemblyLine."Location Code");
                AssemblyLine.Validate("Quantity per", bomQuantity);
                AssemblyLine.Insert();
            end;
            AssembletoOrderLink.Reset();
            AssembletoOrderLink.SetRange("Assembly Document No.", NewNo);
            AssembletoOrderLink.SetRange("Assembly Document Type", AssembletoOrderLink."Assembly Document Type"::Order);
            AssembletoOrderLink.SetRange("Document No.", Tmpsalesline."Document No.");
            AssembletoOrderLink.SetRange("Document Type", AssembletoOrderLink."Document Type"::Order);
            AssembletoOrderLink.SetRange("Document Line No.", Tmpsalesline."Line No.");
            if not AssembletoOrderLink.FindSet() then begin
                AssembletoOrderLink.Init();
                AssembletoOrderLink."Assembly Document No." := NewNo;
                AssembletoOrderLink."Assembly Document Type" := AssembletoOrderLink."Assembly Document Type"::Order;
                AssembletoOrderLink."Document Type" := AssembletoOrderLink."Document Type"::Order;
                AssembletoOrderLink."Document No." := Tmpsalesline."Document No.";
                AssembletoOrderLink.Type := AssembletoOrderLink.Type::Sale;
                AssembletoOrderLink."Document Line No." := Tmpsalesline."Line No.";
                AssembletoOrderLink.Insert();
            end;
        end else begin

            bomLineNo := bomLineNo * 10000;
            AssemblyLine.Reset();
            AssemblyLine.SetRange("Document No.", CheckAssembletoOrderLink."Assembly Document No.");
            AssemblyLine.SetRange("No.", bomItemNo);
            AssemblyLine.SetRange("Document Type", AssemblyLine."Document Type"::Order);
            AssemblyLine.SetRange("Line No.", bomLineNo);
            if not AssemblyLine.FindSet() then begin
                AssemblyLine.Init();
                AssemblyLine."Document No." := CheckAssembletoOrderLink."Assembly Document No.";
                AssemblyLine."Document Type" := AssemblyLine."Document Type"::Order;
                AssemblyLine."Line No." := bomLineNo;
                AssemblyLine.Validate(Type, AssemblyLine.Type::Item);
                AssemblyLine.Validate("No.", bomItemNo);
                AssemblyLine.Validate("Location Code", AssemblyLine."Location Code");
                AssemblyLine.Validate("Quantity per", bomQuantity);
                AssemblyLine.Insert();
            end;
        end;
    end;

    local procedure INSERT_TMPAssemblyBOM(Tmpsalesline: Record "Sales Line" temporary; bomLineNo: Integer; bomItemNo: Code[20]; bomQuantity: Decimal)
    var
        // CheckAssembletoOrderLink: Record "Assemble-to-Order Link";
        // AssemblySetup: Record "Assembly Setup";
        // NoSeriesMgt: Codeunit NoSeriesManagement;
        // OldNoSeriesCode: code[20];
        // NewDate: date;
        NewNo: code[20];
    // OldNo: code[20];
    // NewNoSeriesCode: code[20];
    begin
        // Clear(OldNoSeriesCode);
        // Clear(NewDate);
        Clear(NewNo);
        // Clear(OldNo);
        //AssemblySetup.Get();
        NewNo := StrSubstNo('%1', 'TEMP001');
        TMPAssembletoOrderLink.Reset();
        TMPAssembletoOrderLink.SetRange("Assembly Document Type", TMPAssembletoOrderLink."Assembly Document Type"::Order);
        TMPAssembletoOrderLink.SetRange("Document No.", Tmpsalesline."Document No.");
        TMPAssembletoOrderLink.SetRange("Document Type", TMPAssembletoOrderLink."Document Type"::Order);
        TMPAssembletoOrderLink.SetRange("Document Line No.", Tmpsalesline."Line No.");
        if not TMPAssembletoOrderLink.FindSet() then begin
            //NoSeriesMgt.InitSeries(AssemblySetup."Assembly Order Nos.", OldNoSeriesCode, NewDate, NewNo, NewNoSeriesCode);
            TMPAssemblyHeader.Reset();
            TMPAssemblyHeader.SetRange("No.", NewNo);
            TMPAssemblyHeader.SetRange("Document Type", TMPAssemblyHeader."Document Type"::Order);
            if not TMPAssemblyHeader.FindSet() then begin
                TMPAssemblyHeader.Init();
                TMPAssemblyHeader."No." := NewNo;
                TMPAssemblyHeader."Document Type" := TMPAssemblyHeader."Document Type"::Order;
                TMPAssemblyHeader."Posting Date" := WorkDate();
                TMPAssemblyHeader."Due Date" := WorkDate();
                TMPAssemblyHeader."Starting Date" := WorkDate();
                TMPAssemblyHeader."Ending Date" := WorkDate();
                TMPAssemblyHeader."Item No." := Tmpsalesline."No.";
                TMPAssemblyHeader.Quantity := Tmpsalesline.Quantity;
                TMPAssemblyHeader."Location Code" := Tmpsalesline."Location Code";
                TMPAssemblyHeader.Status := TMPAssemblyHeader.Status::Open;
                TMPAssemblyHeader.Insert();
            end;
            bomLineNo := bomLineNo * 10000;
            TMPAssemblyLine.Reset();
            TMPAssemblyLine.SetRange("Document No.", NewNo);
            TMPAssemblyLine.SetRange("Document Type", TMPAssemblyHeader."Document Type");
            TMPAssemblyLine.SetRange("Line No.", bomLineNo);
            if not TMPAssemblyLine.FindSet() then begin
                TMPAssemblyLine.Init();
                TMPAssemblyLine."Document No." := NewNo;
                TMPAssemblyLine."Document Type" := TMPAssemblyLine."Document Type"::Order;
                TMPAssemblyLine."Line No." := bomLineNo;
                TMPAssemblyLine.Type := TMPAssemblyLine.Type::Item;
                TMPAssemblyLine."No." := bomItemNo;
                TMPAssemblyLine."Location Code" := Tmpsalesline."Location Code";
                TMPAssemblyLine."Quantity per" := bomQuantity;
                TMPAssemblyLine.Insert();
            end;
            TMPAssembletoOrderLink.Reset();
            TMPAssembletoOrderLink.SetRange("Assembly Document No.", NewNo);
            TMPAssembletoOrderLink.SetRange("Assembly Document Type", TMPAssembletoOrderLink."Assembly Document Type"::Order);
            TMPAssembletoOrderLink.SetRange("Document No.", Tmpsalesline."Document No.");
            TMPAssembletoOrderLink.SetRange("Document Type", TMPAssembletoOrderLink."Document Type"::Order);
            TMPAssembletoOrderLink.SetRange("Document Line No.", Tmpsalesline."Line No.");
            if not TMPAssembletoOrderLink.FindSet() then begin
                TMPAssembletoOrderLink.Init();
                TMPAssembletoOrderLink."Assembly Document No." := NewNo;
                TMPAssembletoOrderLink."Assembly Document Type" := TMPAssembletoOrderLink."Assembly Document Type"::Order;
                TMPAssembletoOrderLink."Document Type" := TMPAssembletoOrderLink."Document Type"::Order;
                TMPAssembletoOrderLink."Document No." := Tmpsalesline."Document No.";
                TMPAssembletoOrderLink.Type := TMPAssembletoOrderLink.Type::Sale;
                TMPAssembletoOrderLink."Document Line No." := Tmpsalesline."Line No.";
                TMPAssembletoOrderLink.Insert();
            end;
        end else begin

            bomLineNo := bomLineNo * 10000;
            TMPAssemblyLine.Reset();
            TMPAssemblyLine.SetRange("Document No.", TMPAssembletoOrderLink."Assembly Document No.");
            TMPAssemblyLine.SetRange("No.", bomItemNo);
            TMPAssemblyLine.SetRange("Document Type", TMPAssemblyLine."Document Type"::Order);
            TMPAssemblyLine.SetRange("Line No.", bomLineNo);
            if not TMPAssemblyLine.FindSet() then begin
                TMPAssemblyLine.Init();
                TMPAssemblyLine."Document No." := TMPAssembletoOrderLink."Assembly Document No.";
                TMPAssemblyLine."Document Type" := TMPAssemblyLine."Document Type"::Order;
                TMPAssemblyLine."Line No." := bomLineNo;
                TMPAssemblyLine.Type := TMPAssemblyLine.Type::Item;
                TMPAssemblyLine."No." := bomItemNo;
                TMPAssemblyLine."Location Code" := Tmpsalesline."Location Code";
                TMPAssemblyLine."Quantity per" := bomQuantity;
                TMPAssemblyLine.Insert();
            end;
        end;
    end;

    local procedure INSERT_AssemblyBOM(Tmpsalesline: Record "Sales Line" temporary)
    var
        AssemblyLine: Record "Assembly Line";
        AssemblyHeader: Record "Assembly Header";
        AssembletoOrderLink: Record "Assemble-to-Order Link";
        CheckAssembletoOrderLink: Record "Assemble-to-Order Link";
        AssemblySetup: Record "Assembly Setup";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        LineNo: Integer;
        LocDocumentNo: Code[20];
        OldNoSeriesCode: code[20];
        NewDate: date;
        NewNo: code[20];
        OldNo: code[20];
        NewNoSeriesCode: code[20];
    begin
        Clear(OldNoSeriesCode);
        Clear(NewDate);
        Clear(NewNo);
        Clear(OldNo);
        AssemblySetup.Get();
        CheckAssembletoOrderLink.Reset();
        CheckAssembletoOrderLink.SetRange("Assembly Document Type", CheckAssembletoOrderLink."Assembly Document Type"::Order);
        CheckAssembletoOrderLink.SetRange("Document No.", Tmpsalesline."Document No.");
        CheckAssembletoOrderLink.SetRange("Document Type", CheckAssembletoOrderLink."Document Type"::Order);
        CheckAssembletoOrderLink.SetRange("Document Line No.", Tmpsalesline."Line No.");
        if CheckAssembletoOrderLink.IsEmpty() then begin
            NoSeriesMgt.InitSeries(AssemblySetup."Assembly Order Nos.", OldNoSeriesCode, NewDate, NewNo, NewNoSeriesCode);

            if TMPAssemblyHeader.FindSet() then begin
                AssemblyHeader.Reset();
                AssemblyHeader.SetRange("No.", NewNo);
                AssemblyHeader.SetRange("Document Type", AssemblyHeader."Document Type"::Order);
                if not AssemblyHeader.FindSet() then begin
                    AssemblyHeader.Init();
                    AssemblyHeader.TransferFields(TMPAssemblyHeader);
                    AssemblyHeader."No." := NewNo;
                    AssemblyHeader."Document Type" := TMPAssemblyHeader."Document Type"::Order;
                    AssemblyHeader."Posting Date" := WorkDate();
                    AssemblyHeader."Due Date" := WorkDate();
                    AssemblyHeader."Starting Date" := WorkDate();
                    AssemblyHeader."Ending Date" := WorkDate();
                    AssemblyHeader.Validate("Item No.", Tmpsalesline."No.");
                    AssemblyHeader.Validate(Quantity, 1);
                    AssemblyHeader.Validate("Location Code", Tmpsalesline."Location Code");
                    AssemblyHeader."No. Series" := AssemblySetup."Assembly Order Nos.";
                    AssemblyHeader."Posting No. Series" := AssemblySetup."Posted Assembly Order Nos.";
                    AssemblyHeader.Status := AssemblyHeader.Status::Open;
                    AssemblyHeader.Insert();
                end;
            end;
            if TMPAssembletoOrderLink.FindSet() then begin
                AssembletoOrderLink.Reset();
                AssembletoOrderLink.SetRange("Assembly Document No.", NewNo);
                AssembletoOrderLink.SetRange("Assembly Document Type", TMPAssembletoOrderLink."Assembly Document Type"::Order);
                AssembletoOrderLink.SetRange("Document No.", Tmpsalesline."Document No.");
                AssembletoOrderLink.SetRange("Document Type", TMPAssembletoOrderLink."Document Type"::Order);
                AssembletoOrderLink.SetRange("Document Line No.", Tmpsalesline."Line No.");
                if not AssembletoOrderLink.FindSet() then begin
                    AssembletoOrderLink.Init();
                    AssembletoOrderLink."Assembly Document No." := NewNo;
                    AssembletoOrderLink."Assembly Document Type" := AssembletoOrderLink."Assembly Document Type"::Order;
                    AssembletoOrderLink."Document Type" := AssembletoOrderLink."Document Type"::Order;
                    AssembletoOrderLink."Document No." := Tmpsalesline."Document No.";
                    AssembletoOrderLink.Type := AssembletoOrderLink.Type::Sale;
                    AssembletoOrderLink."Document Line No." := Tmpsalesline."Line No.";
                    AssembletoOrderLink.Insert();

                    Clear(LineNo);
                    clear(LocDocumentNo);
                    TMPAssemblyLine.Reset();
                    TMPAssemblyLine.SetFilter("Document No.", '<>%1', '');
                    if TMPAssemblyLine.FindSet() then
                        repeat
                            if LocDocumentNo <> TMPAssemblyLine."Document No." then begin
                                LocDocumentNo := TMPAssemblyLine."Document No.";
                                LineNo := 0;
                            end;
                            LineNo += 10000;
                            AssemblyLine.Reset();
                            AssemblyLine.SetRange("Document No.", NewNo);
                            AssemblyLine.SetRange("No.", TMPAssemblyLine."No.");
                            AssemblyLine.SetRange("Document Type", AssemblyLine."Document Type"::Order);
                            AssemblyLine.SetRange("Line No.", LineNo);
                            if not AssemblyLine.FindSet() then begin
                                AssemblyLine.Init();
                                AssemblyLine."Document No." := NewNo;
                                AssemblyLine."Document Type" := AssemblyLine."Document Type"::Order;
                                AssemblyLine."Line No." := LineNo;
                                AssemblyLine.Validate(Type, AssemblyLine.Type::Item);
                                AssemblyLine.Validate("No.", TMPAssemblyLine."No.");
                                AssemblyLine.Validate("Location Code", Tmpsalesline."Location Code");
                                AssemblyLine.Validate("Quantity per", 1);
                                AssemblyLine.Insert();
                            end;
                        until TMPAssemblyLine.Next() = 0;

                end;
            end;
        end;
    end;

    procedure AssistEdit(OldAssemblyHeader: Record "Assembly Header"): Boolean
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyHeader2: Record "Assembly Header";
        AssemblySetup: Record "Assembly Setup";
        NoSeriesMgt: Codeunit NoSeriesManagement;
    begin
        with AssemblyHeader do begin
            //Copy(Rec);
            AssemblySetup.Get();
            //TestNoSeries();
            if NoSeriesMgt.SelectSeries(AssemblySetup."Assembly Order Nos.", OldAssemblyHeader."No. Series", "No. Series") then begin
                NoSeriesMgt.SetSeries("No.");
                if AssemblyHeader2.Get("Document Type", "No.") then
                    Error(Text001, Format("Document Type"), "No.");
                //Rec := AssemblyHeader;
                exit(true);
            end;
        end;
    end;

    procedure GetLastEntry() pLastEntryNo: Integer
    var
        LastReservationEntry: Record "Reservation Entry";
        LastEntryNo: Integer;
    begin
        Clear(pLastEntryNo);
        LastReservationEntry.Reset();
        if LastReservationEntry.FindLast() then
            LastEntryNo := LastReservationEntry."Entry No.";
        pLastEntryNo := LastEntryNo + 1;
    end;

    procedure GenerateTempPurchOrder(IsGenHeader: Boolean; pAPIResult: Text; PurchHeader: Record "Purchase Header")
    var
        StoreLocation: Record "LSC Store Location";
        LocItemVariantRegistration: Record "LSC Item Variant Registration";
        PaymentTerms: Record "Payment Terms";
        PaymentMethod: Record "Payment Method";
        lcVariant: Text;
        MinusQtyFound: Boolean;
        AccountingDate: DateTime;
        DeliveryDate: DateTime;
        PricesIncludeSalesTax: Text;
        VendorName: Text[100];
        VendorAccount: Code[20];
        PaymentTermsCode: Code[20];
        PaymentMethodCode: Code[20];
        Status: text;
    begin
        TempPurchHeader.DeleteAll();
        TempPurchLine.DeleteAll();
        MinusQtyFound := FALSE;

        Clear(JSONMgt);
        Clear(JObjectData);
        Clear(JArrayData);
        Clear(AccountingDate);
        Clear(PricesIncludeSalesTax);
        Clear(VendorName);
        Clear(PaymentTermsCode);
        Clear(PaymentMethodCode);
        Clear(Status);
        Window.OPEN('Generate Purchase No. #1############################');
        JArrayData.ReadFrom(pAPIResult);
        foreach JToken in JArrayData do begin
            JObjectData := JToken.AsObject();
            if IsGenHeader then begin
                TempPurchHeader.Init();
                TempPurchHeader."Document Type" := TempPurchHeader."Document Type"::Order;

                if JObjectData.Get('PurchaseOrder', JToken) then
                    TempPurchHeader."No." := CopyStr(JToken.AsValue().AsCode(), 1, 20);
                if JObjectData.Get('VendorAccount', JToken) then
                    VendorAccount := CopyStr(JToken.AsValue().AsCode(), 1, 20);
                if JObjectData.Get('InvoiceAccount', JToken) then
                    TempPurchHeader."Pay-to Vendor No." := CopyStr(JToken.AsValue().AsCode(), 1, 20);
                if JObjectData.Get('VendorName', JToken) then
                    VendorName := CopyStr(JToken.AsValue().AsCode(), 1, 100);
                TempPurchHeader."Buy-from Vendor No." := GetVendorInfor(VendorAccount, VendorName);
                if JObjectData.Get('AccountingDate', JToken) then begin
                    AccountingDate := JToken.AsValue().AsDateTime();
                    TempPurchHeader."Order Date" := DT2Date(AccountingDate);
                end;
                if JObjectData.Get('Currency', JToken) then
                    TempPurchHeader."Currency Code" := CopyStr(JToken.AsValue().AsCode(), 1, 10);
                GLSetup.Get();
                if TempPurchHeader."Currency Code" = GLSetup."LCY Code" then
                    TempPurchHeader."Currency Code" := '';
                TempPurchHeader."Document Date" := TempPurchHeader."Order Date";
                if JObjectData.Get('DeliveryDate', JToken) then begin
                    DeliveryDate := JToken.AsValue().AsDateTime();
                    TempPurchHeader."Expected Receipt Date" := DT2Date(DeliveryDate);
                end;
                if JObjectData.Get('DeliveryAddress', JToken) then
                    TempPurchHeader."Ship-to Code" := CopyStr(JToken.AsValue().AsCode(), 1, 10);
                if JObjectData.Get('ModeOfDelivery', JToken) then
                    TempPurchHeader."Shipment Method Code" := CopyStr(JToken.AsValue().AsCode(), 1, 10);
                if JObjectData.Get('TermsOfPayment', JToken) then
                    PaymentTermsCode := CopyStr(JToken.AsValue().AsCode(), 1, 10);
                if PaymentTermsCode <> '' then
                    if not PaymentTerms.Get(PaymentTermsCode) then begin
                        PaymentTerms.Code := CopyStr(PaymentTermsCode, 1, 10);
                        PaymentTerms.Insert();
                    end;


                TempPurchHeader."Payment Terms Code" := CopyStr(PaymentTermsCode, 1, 10);
                if JObjectData.Get('MethodOfPayment', JToken) then
                    PaymentMethodCode := CopyStr(JToken.AsValue().AsCode(), 1, 20);
                if PaymentMethodCode <> '' then
                    if not PaymentMethod.Get(PaymentMethodCode) then begin
                        PaymentMethod.Code := CopyStr(PaymentMethodCode, 1, 10);
                        PaymentMethod.Insert();
                    end;

                TempPurchHeader."Payment Method Code" := CopyStr(PaymentMethodCode, 1, 10);
                //TempPurchHeader."Payment Method Code" := Vend."Payment Method Code";
                if JObjectData.Get('Warehouse', JToken) then
                    TempPurchHeader."Location Code" := CopyStr(JToken.AsValue().AsCode(), 1, 10);

                TempPurchHeader."BPC.Location Code" := TempPurchHeader."Location Code";

                StoreLocation.Reset();
                StoreLocation.SetRange("Location Code", TempPurchHeader."Location Code");
                if StoreLocation.FindFirst() then
                    TempPurchHeader."LSC Store No." := StoreLocation."Store No.";

                if JObjectData.Get('TotalDiscount', JToken) then
                    TempPurchHeader."BPC.Total Discount %" := JToken.AsValue().AsDecimal();
                if JObjectData.Get('PricesIncludeSalesTax', JToken) then begin
                    PricesIncludeSalesTax := JToken.AsValue().AsText();
                    if PricesIncludeSalesTax <> '' then
                        if PricesIncludeSalesTax = 'No' then
                            TempPurchHeader."Prices Including VAT" := false
                        else
                            TempPurchHeader."Prices Including VAT" := true;

                end;
                if JObjectData.Get('PurchaseOrderStatus', JToken) then
                    Status := JToken.AsValue().astext();
                if Status = 'Canceled' then
                    TempPurchHeader.Status := TempPurchHeader.Status::Cancel;

                TempPurchHeader."BPC.Interface" := true;
                TempPurchHeader."BPC.Active" := true;
                TempPurchHeader.Insert();
            end else begin
                TempPurchLine.Init();
                TempPurchLine."Document Type" := PurchHeader."Document Type";
                TempPurchLine."Document No." := PurchHeader."No.";
                TempPurchLine."Buy-from Vendor No." := PurchHeader."Buy-from Vendor No.";
                if JObjectData.Get('LineNumber', JToken) then
                    TempPurchLine."Line No." := JToken.AsValue().AsInteger();
                TempPurchLine."Line No." *= 10000;
                TempPurchLine.Type := TempPurchLine.Type::Item;
                if JObjectData.Get('ItemNumber', JToken) then
                    TempPurchLine."No." := CopyStr(JToken.AsValue().AsCode(), 1, 20);
                if JObjectData.Get('Warehouse', JToken) then
                    TempPurchLine."Location Code" := CopyStr(JToken.AsValue().AsCode(), 1, 10);
                if TempPurchLine."Location Code" <> PurchHeader."Location Code" then
                    Message('Location %1 not found in store %2', TempPurchLine."Location Code", PurchHeader."Location Code");
                if JObjectData.Get('Variant', JToken) then
                    lcVariant := JToken.AsValue().AsText();
                if lcVariant <> '' then begin
                    LocItemVariantRegistration.Reset();
                    LocItemVariantRegistration.SETFILTER("Item No.", '%1', TempPurchLine."No.");
                    LocItemVariantRegistration.SETFILTER("Variant Dimension 1", '%1', lcVariant);
                    if NOT LocItemVariantRegistration.FindSet() then
                        LocItemVariantRegistration.Init();
                    TempPurchLine."Variant Code" := LocItemVariantRegistration.Variant;
                end;
                TempPurchLine."Pay-to Vendor No." := PurchHeader."Pay-to Vendor No.";
                if JObjectData.Get('Quantity', JToken) then
                    TempPurchLine.Quantity := JToken.AsValue().AsDecimal();
                if JObjectData.Get('Unit', JToken) then
                    TempPurchLine."Unit of Measure Code" := CopyStr(JToken.AsValue().AsCode(), 1, 10);
                TempPurchLine."Expected Receipt Date" := PurchHeader."Expected Receipt Date";
                if JObjectData.Get('UnitPrice', JToken) then
                    TempPurchLine."Direct Unit Cost" := JToken.AsValue().AsDecimal();
                // if JObjectData.Get('DiscountPercent', JToken) then
                //     TempPurchLine."Line Discount %" := JToken.AsValue().AsDecimal();
                if JObjectData.Get('Discount', JToken) then
                    TempPurchLine."Line Discount Amount" := JToken.AsValue().AsDecimal();
                if JObjectData.Get('NetAmount', JToken) then
                    TempPurchLine.Amount := JToken.AsValue().AsDecimal();
                if JObjectData.Get('RemainQuantity', JToken) then
                    TempPurchLine."Outstanding Quantity" := JToken.AsValue().AsDecimal();
                TempPurchLine."BPC.Interface" := true;
                TempPurchLine."BPC.Active" := true;
                // if TempPurchLine."Outstanding Quantity" = 0 then
                //     TempPurchLine."BPC.Active" := FALSE;
                TempPurchLine.Insert();
                if MinusQtyFound AND (TempPurchLine.Quantity < 0) then
                    MinusQtyFound := true;
            end;
        end;

        Window.Close();
    end;

    procedure InsertPurchOrder(IsGenHeader: Boolean; pStoreNo: Code[10]; pLocCode: Code[10])
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchLine1: Record "Purchase Line";
        Item: Record Item;
        Item1: Record Item;
        UOMMgt: Codeunit "Unit of Measure Management";
        DataInsert: Boolean;
        Status_Var: Option Open,Released,"Pending Approval","Pending Prepayment";
        Quantity: Decimal;
        OutstandingQuantity: Decimal;
    begin
        Window.OPEN('Insert Purchase No. #1############################');
        PurchSetup.Get();
        Clear(PurchLine1);
        if IsGenHeader then begin
            TempPurchHeader.Reset();
            TempPurchHeader.SetRange("LSC Store No.", pStoreNo);
            // Error(StrSubstNo('InsertPurchOrder - %1', pStoreNo));
            if TempPurchHeader.FindSet() then begin
                GLSetup.Get();
                if TempPurchHeader."Currency Code" = GLSetup."LCY Code" then
                    TempPurchHeader."Currency Code" := '';
                // Clear Active ++
                PurchHeader.Reset();
                PurchHeader.SetRange("LSC Store No.", pStoreNo);
                PurchHeader.SetRange("Location Code", pLocCode);
                PurchHeader.SetRange("BPC.Active", TRUE);
                if PurchHeader.FindSet() then
                    PurchHeader.ModifyAll("BPC.Active", FALSE);
                // Clear Active --
                repeat
                    Window.Update(1, TempPurchHeader."No.");
                    PurchHeader.Reset();
                    PurchHeader.SetRange("Document Type", TempPurchHeader."Document Type");
                    //PurchHeader.SetRange("Buy-from Vendor No.",TempPurchHeader."Buy-from Vendor No.");
                    PurchHeader.SetRange("No.", TempPurchHeader."No.");

                    //PurchHeader.SetRange("Store No.",TempPurchHeader."Store No.");
                    if NOT PurchHeader.FindSet() then begin
                        // INSERT
                        PurchHeader.Init();
                        PurchHeader.TransferFields(TempPurchHeader);
                        PurchHeader.SetHideValidationDialog(TRUE);
                        PurchHeader.Insert();

                        if TempPurchHeader.Status <> TempPurchHeader.Status::Cancel then begin
                            PurchHeader.Validate("Buy-from Vendor No.", TempPurchHeader."Buy-from Vendor No.");
                            PurchHeader.Validate("Pay-to Vendor No.", TempPurchHeader."Pay-to Vendor No.");
                            if PurchHeader."Gen. Bus. Posting Group" = '' then
                                PurchHeader.Validate("Gen. Bus. Posting Group", 'DOMESTIC');
                            if TempPurchHeader."Ship-to Code" <> '' then
                                PurchHeader.Validate("Ship-to Code", TempPurchHeader."Ship-to Code");
                            if TempPurchHeader."Payment Terms Code" <> '' then
                                PurchHeader.Validate("Payment Terms Code", TempPurchHeader."Payment Terms Code");
                            if TempPurchHeader."Buy-from Contact No." <> '' then
                                PurchHeader.Validate("Buy-from Contact No.", TempPurchHeader."Buy-from Contact No.");
                            GLSetup.Get();
                            if TempPurchHeader."Currency Code" = GLSetup."LCY Code" then
                                TempPurchHeader."Currency Code" := '';
                            PurchHeader.Validate("Currency Code", TempPurchHeader."Currency Code");
                            PurchHeader.Validate("Payment Method Code", TempPurchHeader."Payment Method Code");
                            PurchHeader.Validate("LSC Store No.", TempPurchHeader."LSC Store No.");
                            PurchHeader."Location Code" := TempPurchHeader."Location Code";
                            //PurchHeader.Validate("BPC.Total Discount %", TempPurchHeader."BPC.Total Discount %");
                            PurchHeader.Validate(Amount, TempPurchHeader.Amount);
                            PurchHeader."Receiving No. Series" := PurchSetup."Posted Receipt Nos.";
                            PurchHeader."BPC.Location Code" := TempPurchHeader."BPC.Location Code";
                            if TempPurchHeader.Status = TempPurchHeader.Status::Cancel then
                                PurchHeader.Status := PurchHeader.Status::Cancel
                            else
                                PurchHeader.Status := PurchHeader.Status::Released;
                            PurchHeader.Modify();
                        end;
                    end else begin
                        // MODIFY
                        // PurchLine1.Reset();
                        // PurchLine1.SetRange("Document No.", PurchHeader."No.");
                        // PurchLine1.SetRange(PurchLine1."Document Type", PurchLine1."Document Type"::Order);
                        // PurchLine1.SetRange(PurchLine1."Quantity Received", 0);
                        // if PurchLine1.FindSet() then begin
                        //     repeat
                        //         QuantityReceived += PurchLine1."Quantity Received";
                        //     until PurchLine1.Next() = 0;
                        // end;
                        //if QuantityReceived <> 0 then begin
                        Status_Var := PurchHeader.Status;
                        PurchHeader.Status := PurchHeader.Status::Open;
                        PurchHeader.SetHideValidationDialog(TRUE);
                        //PurchHeader."Buy-from Vendor No." := TempPurchHeader."Buy-from Vendor No.";
                        //PurchHeader.Validate("Buy-from Vendor No.", TempPurchHeader."Buy-from Vendor No.");
                        if PurchHeader."Gen. Bus. Posting Group" = '' then
                            PurchHeader.Validate("Gen. Bus. Posting Group", 'DOMESTIC');
                        PurchHeader."Posting Date" := TempPurchHeader."Posting Date";
                        PurchHeader."Order Date" := TempPurchHeader."Order Date";
                        PurchHeader."Document Date" := TempPurchHeader."Document Date";
                        PurchHeader."Expected Receipt Date" := TempPurchHeader."Expected Receipt Date";
                        if TempPurchHeader."Ship-to Code" <> '' then
                            PurchHeader.Validate("Ship-to Code", TempPurchHeader."Ship-to Code");
                        if TempPurchHeader."Payment Terms Code" <> '' then
                            PurchHeader.Validate("Payment Terms Code", TempPurchHeader."Payment Terms Code");
                        GLSetup.Get();
                        // PurchHeader.Validate("Location Code", TempPurchHeader."Location Code");
                        // Joe 2025-03-21 Move ++
                        // PurchHeader.Validate("LSC Store No.", TempPurchHeader."LSC Store No.");
                        // PurchHeader."Location Code" := TempPurchHeader."Location Code";
                        // Joe 2025-03-21 Move --
                        PurchHeader.Validate("Buy-from Vendor No.", TempPurchHeader."Buy-from Vendor No.");
                        if TempPurchHeader."Currency Code" = GLSetup."LCY Code" then
                            TempPurchHeader."Currency Code" := '';
                        PurchHeader.Validate("Currency Code", TempPurchHeader."Currency Code");
                        //PurchHeader."Currency Code" := TempPurchHeader."Currency Code";
                        // PurchHeader."Payment Method Code" := TempPurchHeader."Payment Method Code";
                        // PurchHeader."BPC.Total Discount %" := TempPurchHeader."BPC.Total Discount %";
                        PurchHeader.Validate("Payment Method Code", TempPurchHeader."Payment Method Code");
                        //PurchHeader.Validate("BPC.Total Discount %", TempPurchHeader."BPC.Total Discount %");
                        PurchHeader."Receiving No. Series" := PurchSetup."Posted Receipt Nos.";
                        PurchHeader."BPC.Active" := TempPurchHeader."BPC.Active";
                        // Joe 2025-03-21 Move ++
                        PurchHeader.Validate("LSC Store No.", TempPurchHeader."LSC Store No.");
                        PurchHeader."Location Code" := TempPurchHeader."Location Code";
                        // Joe 2025-03-21 Move --
                        PurchHeader."BPC.Location Code" := TempPurchHeader."BPC.Location Code";
                        //if TempPurchHeader.Status = TempPurchHeader.Status::Cancel then
                        PurchHeader.Status := TempPurchHeader.Status;
                        //else
                        // PurchHeader.Status := Status_Var;

                        // PurchHeader.Modify();
                        //end else begin
                        if TempPurchHeader.Status = TempPurchHeader.Status::Cancel then
                            PurchHeader.Status := PurchHeader.Status::Cancel
                        else
                            PurchHeader.Status := PurchHeader.Status::Released;
                        PurchHeader.Modify();
                        //end;
                    end;
                until TempPurchHeader.Next() = 0;
            end;
        end else begin
            Clear(JsonUtil);
            TempPurchLine.Reset();
            if TempPurchLine.FindSet() then begin
                // TempPurchLine.CalcSums(Quantity);
                // if TempPurchLine.Quantity = 0 then begin
                //     PurchHeader.Reset();
                //     PurchHeader.SetRange("No.", TempPurchLine."Document No.");
                //     if PurchHeader.FindSet() then
                //         PurchHeader.Status := PurchHeader.Status::Cancel;

                //     exit;
                // end;
                // Clear Active ++
                PurchLine.Reset();
                PurchLine.SetRange("Document Type", TempPurchLine."Document Type");
                PurchLine.SetRange("Document No.", TempPurchLine."Document No.");
                PurchLine.SetRange("BPC.Active", TRUE);
                if PurchLine.FindSet() then
                    PurchLine.ModifyAll("BPC.Active", FALSE);
                // CheckCancelPurchHeader.Reset();
                // CheckCancelPurchHeader.SetRange("No.", TempPurchLine."Document No.");
                // CheckCancelPurchHeader.SetRange(status, CheckCancelPurchHeader.Status::Cancel);
                // if not CheckCancelPurchHeader.FindSet() then begin
                // Clear Active --
                JsonUtil.StartJSon();
                repeat
                    // Check Data ++
                    DataInsert := true;
                    if NOT Item.Get(TempPurchLine."No.") then
                        DataInsert := FALSE;

                    // Check Data --
                    if DataInsert then
                        if NOT PurchLine.Get(TempPurchLine."Document Type", TempPurchLine."Document No.", TempPurchLine."Line No.") then begin
                            Window.Update(1, TempPurchLine."Document No.");
                            PurchLine.Init();
                            PurchLine.TransferFields(TempPurchLine);
                            PurchLine.Insert();
                            PurchLine.Validate("No.", TempPurchLine."No.");
                            PurchLine.Validate("Variant Code", TempPurchLine."Variant Code");
                            if PurchLine."Gen. Bus. Posting Group" = '' then
                                PurchLine.Validate("Gen. Bus. Posting Group", 'DOMESTIC');
                            if PurchLine."Gen. Prod. Posting Group" = '' then
                                PurchLine.Validate("Gen. Prod. Posting Group", 'FG');
                            if not Item1.Get(PurchLine."No.") then
                                Item1.Init();
                            PurchLine."Location Code" := TempPurchLine."Location Code";
                            PurchLine."Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(Item1, TempPurchLine."Unit of Measure Code");
                            //PurchLine.Validate("Location Code",TempPurchLine."Location Code");
                            PurchLine."Location Code" := TempPurchLine."Location Code";
                            PurchLine.Validate("Amount Including VAT", TempPurchLine."Amount Including VAT");
                            PurchLine.Validate("Unit of Measure Code", TempPurchLine."Unit of Measure Code");
                            PurchLine.Validate(Quantity, TempPurchLine.Quantity);
                            Quantity := TempPurchLine.Quantity;
                            if Quantity < 0 then
                                PurchLine.Validate("Line Discount Amount", -TempPurchLine."Line Discount Amount")
                            else
                                PurchLine.Validate("Line Discount Amount", TempPurchLine."Line Discount Amount");

                            PurchLine.Validate("Direct Unit Cost", TempPurchLine."Direct Unit Cost");
                            PurchLine.Validate("VAT %", TempPurchLine."VAT %");
                            //PurchLine.Validate("Line Discount %", TempPurchLine."Line Discount %");
                            PurchLine.Validate(Amount, TempPurchLine.Amount);
                            PurchLine."Outstanding Quantity" := TempPurchLine."Outstanding Quantity";
                            PurchLine."Outstanding Qty. (Base)" := PurchLine."Outstanding Quantity" * PurchLine."Qty. per Unit of Measure";

                            //PurchLine.InitOutstanding; //DRPH
                            //PurchLine.InitOutstandingAmount; //DRPH
                            PurchLine."BPC.Active" := TempPurchLine."BPC.Active";
                            PurchLine."Qty. to Receive" := 0;
                            PurchLine.Modify();
                        end else begin
                            //if PurchLine."Quantity Received" <> 0 then begin
                            PurchLine.Validate("Variant Code", TempPurchLine."Variant Code");
                            if PurchLine."Gen. Bus. Posting Group" = '' then
                                PurchLine.Validate("Gen. Bus. Posting Group", 'DOMESTIC');
                            if PurchLine."Gen. Prod. Posting Group" = '' then
                                PurchLine.Validate("Gen. Prod. Posting Group", 'FG');
                            //PurchLine.Validate("Location Code",TempPurchLine."Location Code");
                            if not Item1.Get(PurchLine."No.") then
                                Item1.Init();
                            PurchLine."Location Code" := TempPurchLine."Location Code";
                            PurchLine."Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(Item1, TempPurchLine."Unit of Measure Code");
                            PurchLine.Validate("Amount Including VAT", TempPurchLine."Amount Including VAT");
                            if TempPurchLine."Outstanding Quantity" <> 0 then begin
                                if (PurchLine."Quantity Received" = 0) and (PurchLine."Qty. Received (Base)" = 0) then
                                    PurchLine.Validate("Unit of Measure Code", TempPurchLine."Unit of Measure Code");
                                PurchLine.Validate(Quantity, TempPurchLine.Quantity);
                                Quantity := TempPurchLine.Quantity;
                                if Quantity < 0 then
                                    PurchLine.Validate("Line Discount Amount", -TempPurchLine."Line Discount Amount")
                                else
                                    PurchLine.Validate("Line Discount Amount", TempPurchLine."Line Discount Amount");

                                PurchLine.Validate("Direct Unit Cost", TempPurchLine."Direct Unit Cost");
                                PurchLine.Validate("VAT %", TempPurchLine."VAT %");
                                //PurchLine.Validate("Line Discount %", TempPurchLine."Line Discount %");
                                //PurchLine.Validate("Line Discount Amount", TempPurchLine."Line Discount Amount");
                                PurchLine.Validate(Amount, TempPurchLine.Amount);
                                OutstandingQuantity := PurchLine."Outstanding Quantity";
                                PurchLine."Outstanding Quantity" := TempPurchLine."Outstanding Quantity";
                                PurchLine."Qty. Received (Base)" := PurchLine."Quantity" - OutstandingQuantity;
                                PurchLine."Outstanding Qty. (Base)" := PurchLine."Outstanding Quantity" * PurchLine."Qty. per Unit of Measure";
                            end else //begin
                                // PurchLine."Unit of Measure Code" := TempPurchLine."Unit of Measure Code";
                                // PurchLine.Quantity := TempPurchLine.Quantity;
                                // Quantity := TempPurchLine.Quantity;
                                // if Quantity < 0 then
                                //     PurchLine.Validate("Line Discount Amount", -TempPurchLine."Line Discount Amount")
                                // else
                                //     PurchLine.Validate("Line Discount Amount", TempPurchLine."Line Discount Amount");

                                // PurchLine."Quantity (Base)" := TempPurchLine.Quantity * TempPurchLine."Qty. per Unit of Measure";
                                // PurchLine."Direct Unit Cost" := TempPurchLine."Direct Unit Cost";
                                // PurchLine."VAT %" := TempPurchLine."VAT %";
                                // //PurchLine."Line Discount %" := TempPurchLine."Line Discount %";
                                // //PurchLine."Line Discount Amount" := TempPurchLine."Line Discount Amount";
                                // PurchLine."Outstanding Quantity" := 0;
                                // PurchLine."Outstanding Qty. (Base)" := 0;
                                // PurchLine.Quantity := 0;
                                // TODO:TempPurchLine.Quantity
                                if TempSalesLine."Outstanding Quantity" = 0 then begin
                                    // PurchLine."BPC Qty. to Cancel" := PurchLine.Quantity;
                                    // PurchLine."BPC Qty. to Cancel (Base)" := PurchLine.Quantity;
                                    PurchLine."BPC Qty. to Cancel" := PurchLine."Outstanding Quantity";
                                    PurchLine."BPC Qty. to Cancel (Base)" := PurchLine."Outstanding Qty. (Base)";
                                    PurchLine.InitOutstanding();
                                end;
                            //end;

                            // PurchLine.InitOutstanding; //DRPH
                            // PurchLine.InitOutstandingAmount; //DRPH
                            PurchLine."Qty. to Receive" := 0;
                            PurchLine."BPC.Active" := TempPurchLine."BPC.Active";
                            PurchLine.MODIFY(true);
                            //end;
                        end;

                until TempPurchLine.Next() = 0;
                // end else begin
                //     error('PO %1 Cancel', CheckCancelPurchHeader."No.");
                //end;
                // Delete Line ++
                PurchLine.Reset();
                PurchLine.SetRange("Document Type", TempPurchLine."Document Type");
                PurchLine.SetRange("Document No.", TempPurchLine."Document No.");
                PurchLine.SetRange("BPC.Active", FALSE);
                if PurchLine.FindSet() then
                    PurchLine.DeleteAll();
                // Delete Line --
            end;
        end;
        Commit();
        Window.Close();
    end;

    procedure InsertSalesOrder(IsGenHeader: Boolean; pStoreNo: Code[10]; pLocCode: Code[10]; Var pSalesHeader: Record "sales Header")
    var
        SalesHeader: Record "sales Header";
        // SalesHeader1: Record "sales Header";
        SalesLine: Record "sales Line";
        // Item: Record Item;
        Item1: Record Item;
        SalesShipmentHeader: Record "Sales Shipment Header";
        // InterfaceDocumentStatus: Record "BPC.Interface Document Status";
        Customer: Record Customer;
        UOMMgt: Codeunit "Unit of Measure Management";
        CalcDiscByType: Codeunit 56;
        // DataInsert: Boolean;
        // Status_Var: Option Open,Released,"Pending Approval","Pending Prepayment";
        countline: Integer;
    begin
        Window.OPEN('Insert sales No. #1############################');

        if IsGenHeader then begin
            TempSalesHeader.Reset();
            TempSalesHeader.SetRange("LSC Store No.", pStoreNo);
            if TempSalesHeader.FindSet() then begin
                GLSetup.Get();
                if TempSalesHeader."Currency Code" = GLSetup."LCY Code" then
                    TempSalesHeader."Currency Code" := '';
                // Clear Active ++
                SalesHeader.Reset();
                SalesHeader.SetRange("LSC Store No.", pStoreNo);
                SalesHeader.SetRange("Location Code", pLocCode);
                SalesHeader.SetRange("BPC.Active", TRUE);
                if SalesHeader.FindSet() then
                    SalesHeader.ModifyAll("BPC.Active", FALSE);
                // Clear Active --
                repeat
                    SalesShipmentHeader.Reset();
                    SalesShipmentHeader.SetRange("Order No.", TempSalesHeader."No.");
                    if (not SalesShipmentHeader.FindFirst()) then begin
                        Window.Update(1, TempSalesHeader."No.");
                        SalesHeader.Reset();
                        SalesHeader.SetRange("Document Type", TempSalesHeader."Document Type");
                        //SalesHeader.SetRange("Sell-to Customer No.", TempSalesHeader."Sell-to Customer No.");
                        SalesHeader.SetRange("No.", TempSalesHeader."No.");
                        //SalesHeader.SetRange("LSC Store No.", TempSalesHeader."LSC Store No.");
                        if NOT SalesHeader.FindSet() then begin
                            // INSERT
                            SalesHeader.Init();
                            SalesHeader.TransferFields(TempSalesHeader);
                            SalesHeader.SetHideValidationDialog(TRUE);
                            SalesHeader.Status := SalesHeader.Status::Open;
                            SalesHeader.Insert();
                            SalesHeader."Document Date" := Today();
                            SalesHeader."Posting Date" := Today();

                            if not Customer.Get(TempSalesHeader."Sell-to Customer No.") then
                                Customer.Init();

                            SalesHeader.Validate("Sell-to Customer No.", TempSalesHeader."Sell-to Customer No.");
                            SalesHeader."Sell-to Customer Name" := TempSalesHeader."Sell-to Customer Name";
                            SalesHeader.Validate("LSC Store No.", TempSalesHeader."LSC Store No.");
                            SalesHeader.Validate("VAT Bus. Posting Group", Customer."VAT Bus. Posting Group");
                            SalesHeader.Validate("Gen. Bus. Posting Group", Customer."Gen. Bus. Posting Group");

                            if not Customer."BPC.API Not Update Customer" then
                                SalesHeader.Validate("Bill-to Customer No.", TempSalesHeader."Bill-to Customer No.")
                            else
                                SalesHeader."Bill-to Customer No." := TempSalesHeader."Bill-to Customer No.";

                            SalesHeader.Validate("Invoice Discount Value", TempSalesHeader."Invoice Discount Value");


                            SalesHeader.Validate("Prices Including VAT", TempSalesHeader."Prices Including VAT");
                            if TempSalesHeader."Location Code" <> '' then
                                SalesHeader."Location Code" := TempSalesHeader."Location Code";

                            SalesHeader."Bill-to Name" := TempSalesHeader."Bill-to Name";
                            SalesHeader."Bill-to Address" := TempSalesHeader."Bill-to Address";
                            SalesHeader."Bill-to Address 2" := TempSalesHeader."Bill-to Address 2";
                            SalesHeader."Bill-to Post Code" := TempSalesHeader."Bill-to Post Code";
                            SalesHeader."Bill-to City" := TempSalesHeader."Bill-to City";
                            SalesHeader."Bill-to Country/Region Code" := TempSalesHeader."Bill-to Country/Region Code";
                            SalesHeader."Ship-to Address" := TempSalesHeader."Ship-to Address";
                            SalesHeader."Ship-to Address 2" := TempSalesHeader."Ship-to Address 2";
                            SalesHeader."Ship-to Post Code" := TempSalesHeader."Ship-to Post Code";
                            SalesHeader."Ship-to City" := TempSalesHeader."Ship-to City";
                            SalesHeader."Ship-to County" := TempSalesHeader."Ship-to County";
                            SalesHeader."Ship-to Name" := TempSalesHeader."Ship-to Name";
                            SalesHeader."Sell-to Address" := TempSalesHeader."Sell-to Address";
                            SalesHeader."Sell-to Address 2" := TempSalesHeader."Sell-to Address 2";
                            SalesHeader."Sell-to Post Code" := TempSalesHeader."Sell-to Post Code";
                            SalesHeader."Sell-to City" := TempSalesHeader."Sell-to City";
                            SalesHeader."Sell-to Contact" := TempSalesHeader."Sell-to Contact";
                            SalesHeader."BPC.Location Code" := TempSalesHeader."BPC.Location Code";
                            SalesHeader."BPC.Interface" := true;
                            SalesHeader."BPC.Active" := true;

                            // Joe 2025-04-04 ++
                            // if TempSalesHeader."Ship-to Code" <> '' then
                            //     SalesHeader.Validate("Ship-to Code", TempSalesHeader."Ship-to Code");
                            // Joe 2025-04-04 --

                            // SalesHeader.Status := SalesHeader.Status::Released;

                            if TempSalesHeader.Status = TempSalesHeader.Status::Cancel then
                                SalesHeader.Status := SalesHeader.Status::Cancel
                            else
                                SalesHeader.Status := SalesHeader.Status::Released;

                            SalesHeader.Modify();

                        end else begin
                            // MODIFY
                            SalesHeader.Status := SalesHeader.Status::Open;
                            SalesHeader."Document Type" := TempSalesHeader."Document Type";
                            if not Customer.Get(TempSalesHeader."Sell-to Customer No.") then
                                Customer.Init();

                            if (Customer."Gen. Bus. Posting Group" <> '') and (Customer."VAT Bus. Posting Group" <> '') then
                                SalesHeader.Validate("Sell-to Customer No.", TempSalesHeader."Sell-to Customer No.");

                            if SalesHeader."Gen. Bus. Posting Group" = '' then
                                SalesHeader.Validate("Gen. Bus. Posting Group", Customer."Gen. Bus. Posting Group");
                            if SalesHeader."Gen. Bus. Posting Group" = '' then
                                SalesHeader.Validate("VAT Bus. Posting Group", Customer."VAT Bus. Posting Group");

                            //SalesHeader.Validate("Location Code", TempSalesHeader."Location Code");
                            SalesHeader.Validate("Invoice Discount Value", TempSalesHeader."Invoice Discount Value");
                            SalesHeader.Validate("LSC Store No.", TempSalesHeader."LSC Store No.");
                            if SalesHeader."Prices Including VAT" <> TempSalesHeader."Prices Including VAT" then
                                SalesHeader.Validate("Prices Including VAT", TempSalesHeader."Prices Including VAT");

                            if TempSalesHeader."Location Code" <> '' then
                                SalesHeader."Location Code" := TempSalesHeader."Location Code";
                            SalesHeader."Bill-to Name" := TempSalesHeader."Bill-to Name";
                            SalesHeader."Bill-to Address" := TempSalesHeader."Bill-to Address";
                            SalesHeader."Bill-to Address 2" := TempSalesHeader."Bill-to Address 2";
                            SalesHeader."Bill-to Post Code" := TempSalesHeader."Bill-to Post Code";
                            SalesHeader."Bill-to City" := TempSalesHeader."Bill-to City";
                            SalesHeader."Bill-to Country/Region Code" := TempSalesHeader."Bill-to Country/Region Code";
                            SalesHeader."Ship-to Address" := TempSalesHeader."Ship-to Address";
                            SalesHeader."Ship-to Address 2" := TempSalesHeader."Ship-to Address 2";
                            SalesHeader."Ship-to Post Code" := TempSalesHeader."Ship-to Post Code";
                            SalesHeader."Ship-to City" := TempSalesHeader."Ship-to City";
                            SalesHeader."Ship-to County" := TempSalesHeader."Ship-to County";
                            SalesHeader."Ship-to Name" := TempSalesHeader."Ship-to Name";
                            SalesHeader."Bill-to Customer No." := TempSalesHeader."Bill-to Customer No.";
                            SalesHeader."VAT Registration No." := TempSalesHeader."VAT Registration No.";
                            // Update Customer Joe 2025/03/19
                            SalesHeader."Sell-to Customer Name" := TempSalesHeader."Sell-to Customer Name";
                            SalesHeader."Sell-to Address" := TempSalesHeader."Sell-to Address";
                            SalesHeader."Sell-to Address 2" := TempSalesHeader."Sell-to Address 2";
                            SalesHeader."Sell-to Post Code" := TempSalesHeader."Sell-to Post Code";
                            SalesHeader."Sell-to City" := TempSalesHeader."Sell-to City";
                            SalesHeader."Sell-to Contact" := TempSalesHeader."Sell-to Contact";
                            SalesHeader."BPC.Location Code" := TempSalesHeader."BPC.Location Code";
                            SalesHeader."BPC.Reference Online Order" := TempSalesHeader."BPC.Reference Online Order";
                            SalesHeader."BPC.Interface" := true;
                            SalesHeader."BPC.Active" := true;

                            // Joe 2025-04-04 ++
                            // if TempSalesHeader."Ship-to Code" <> '' then
                            //     SalesHeader.Validate("Ship-to Code", TempSalesHeader."Ship-to Code");
                            // Joe 2025-04-04 --
                            // SalesHeader.Status := SalesHeader.Status::Released;
                            if TempSalesHeader.Status = TempSalesHeader.Status::Cancel then
                                SalesHeader.Status := SalesHeader.Status::Cancel
                            else
                                SalesHeader.Status := SalesHeader.Status::Released;

                            SalesHeader.Modify();
                        end;
                    end;
                until TempSalesHeader.Next() = 0;
            end;
        end else begin
            Clear(JsonUtil);
            Clear(countline);
            TempSalesLine.Reset();
            if TempSalesLine.FindSet() then begin

                // Clear Active ++
                SalesLine.Reset();
                SalesLine.SetRange("Document Type", TempSalesLine."Document Type");
                SalesLine.SetRange("Document No.", TempSalesLine."Document No.");
                SalesLine.SetRange("BPC.Active", TRUE);
                if SalesLine.FindSet() then
                    SalesLine.ModifyAll("BPC.Active", FALSE);
                // Clear Active --
                JsonUtil.StartJSon();
                repeat
                    if NOT SalesLine.Get(TempSalesLine."Document Type", TempSalesLine."Document No.", TempSalesLine."Line No.") then begin
                        Window.Update(1, TempSalesLine."Document No.");
                        SalesLine.Init();
                        SalesLine.TransferFields(TempSalesLine);
                        SalesLine.Insert();
                        if not Item1.Get(TempSalesLine."No.") then
                            Item1.Init();
                        SalesLine."Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(Item1, TempSalesLine."Unit of Measure Code");
                        SalesLine.Validate(Quantity, TempSalesLine.Quantity);
                        SalesLine.Validate("Sell-to Customer No.", pSalesHeader."Sell-to Customer No.");
                        SalesLine.Validate("Bill-to Customer No.", pSalesHeader."Bill-to Customer No.");
                        if not Customer.Get(pSalesHeader."Sell-to Customer No.") then
                            Customer.Init();

                        SalesLine.Validate("VAT Bus. Posting Group", Customer."VAT Bus. Posting Group");
                        SalesLine.Validate("Gen. Bus. Posting Group", Customer."Gen. Bus. Posting Group");
                        SalesLine.Validate("Gen. Prod. Posting Group", 'FG');
                        SalesLine.Validate("VAT Prod. Posting Group", Item1."VAT Prod. Posting Group");
                        SalesLine.Validate("Unit Price", TempSalesLine."Unit Price");
                        SalesLine.Validate("Line Discount Amount", TempSalesLine."Line Discount Amount");
                        SalesLine.Validate("Location Code", pSalesHeader."Location Code");
                        //SalesLine.Validate("Qty. to Asm. to Order (Base)", TempSalesLine."Qty. to Asm. to Order (Base)");
                        SalesLine."BPC.Interface" := true;
                        SalesLine."BPC.Active" := true;
                        SalesLine."Outstanding Quantity" := TempSalesLine."Outstanding Quantity";
                        SalesLine.Modify();
                    end else begin
                        //SalesLine."No." := TempSalesLine."No.";
                        SalesLine."Unit of Measure Code" := TempSalesLine."Unit of Measure Code";
                        if not Item1.Get(SalesLine."No.") then
                            Item1.Init();
                        SalesLine."Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(Item1, TempSalesLine."Unit of Measure Code");
                        SalesLine."BPC.Not Check AutoAsmToOrder" := TempSalesLine."BPC.Not Check AutoAsmToOrder";
                        SalesLine.Validate(Description, TempSalesLine.Description);
                        SalesLine."Qty. to Assemble to Order" := TempSalesLine."Qty. to Assemble to Order";
                        SalesLine."Qty. to Asm. to Order (Base)" := TempSalesLine."Qty. to Asm. to Order (Base)";
                        SalesLine.Validate(Quantity, TempSalesLine.Quantity);
                        SalesLine.Validate("Unit Price", TempSalesLine."Unit Price");
                        SalesLine.Validate("Line Discount Amount", TempSalesLine."Line Discount Amount");

                        if not Customer.Get(pSalesHeader."Sell-to Customer No.") then
                            Customer.Init();
                        if (Customer."Gen. Bus. Posting Group" <> '') and (Customer."VAT Bus. Posting Group" <> '') then begin
                            SalesLine.Validate("Sell-to Customer No.", pSalesHeader."Sell-to Customer No.");
                            SalesLine.Validate("Bill-to Customer No.", pSalesHeader."Bill-to Customer No.");
                        end;

                        if SalesLine."VAT Bus. Posting Group" = '' then
                            SalesLine.Validate("VAT Bus. Posting Group", Customer."VAT Bus. Posting Group");
                        if SalesLine."Gen. Bus. Posting Group" = '' then
                            SalesLine.Validate("Gen. Bus. Posting Group", Customer."Gen. Bus. Posting Group");
                        if SalesLine."Gen. Prod. Posting Group" = '' then
                            SalesLine.Validate("Gen. Prod. Posting Group", 'FG');
                        if SalesLine."VAT Prod. Posting Group" = '' then
                            SalesLine.Validate("VAT Prod. Posting Group", Item1."VAT Prod. Posting Group");
                        SalesLine."Location Code" := pSalesHeader."Location Code";
                        //SalesLine.Validate("Qty. to Asm. to Order (Base)", TempSalesLine."Qty. to Asm. to Order (Base)");

                        if TempSalesLine."Outstanding Quantity" = 0 then begin
                            SalesLine."BPC Qty. to Cancel" := SalesLine.Quantity;
                            SalesLine."BPC Qty. to Cancel (Base)" := SalesLine.Quantity;
                        end;

                        SalesLine."BPC.Interface" := true;
                        SalesLine."BPC.Active" := true;
                        SalesLine.Modify();
                    end;

                until TempSalesLine.Next() = 0;
                CalcDiscByType.ApplyInvDiscBasedOnAmt(pSalesHeader."Invoice Discount Value", pSalesHeader)
            end;
        end;
        Window.Close();
        Commit();
    end;

    local procedure GenerateTempTransfOrder(IsGenHeader: Boolean; pAPIResult: Text; TransfHeader: Record "Transfer Header")
    var
        LocItemVariantRegistration: Record "LSC Item Variant Registration";
        lcVariant: Text;
        i: Integer;
        Sign: Decimal;
        EntryNo: Integer;
    begin
        TempTransfHeader.DeleteAll();
        TempTransfLine.DeleteAll();

        Clear(JSONMgt);
        Clear(JObjectData);
        Clear(JArrayData);
        Clear(EntryNo);

        Window.OPEN('Generate Transfer No. #1############################');
        JArrayData.ReadFrom(pAPIResult);
        // if IsGenHeader then begin
        foreach JToken in JArrayData do begin
            JObjectData := JToken.AsObject();
            if IsGenHeader then begin
                TempTransfHeader.Init();
                if JObjectData.Get('Transf_No', JToken) then
                    TempTransfHeader."No." := JToken.AsValue().AsCode();
                if JObjectData.Get('Transf_Transffrom', JToken) then
                    TempTransfHeader."Transfer-from Code" := JToken.AsValue().AsCode();
                if JObjectData.Get('Transf_Transfto', JToken) then
                    TempTransfHeader."Transfer-to Code" := JToken.AsValue().AsCode();
                TempTransfHeader."In-Transit Code" := '69998';
                if JObjectData.Get('Transf_PostingDate', JToken) then
                    TempTransfHeader."Posting Date" := JToken.AsValue().AsDate();
                TempTransfHeader."BPC.Active" := true;
                TempTransfHeader."BPC.Interface" := true;
                TempTransfHeader.Insert();
            end else begin
                TempTransfLine.Init();
                if JObjectData.Get('TransfL_DocNo', JToken) then
                    TempTransfLine."Document No." := JToken.AsValue().AsCode();
                if JObjectData.Get('TransfL_LineNo', JToken) then
                    TempTransfLine."Line No." := JToken.AsValue().AsInteger();
                TempTransfLine."Line No." *= 10000;
                if JObjectData.Get('TransfL_ItemNo', JToken) then
                    TempTransfLine."Item No." := JToken.AsValue().AsCode();
                if JObjectData.Get('TransfL_Location', JToken) then
                    TempTransfLine."BPC.Location Code" := JToken.AsValue().AsCode();
                TempTransfLine."In-Transit Code" := '69998';
                if JObjectData.Get('TransfL_Variant', JToken) then
                    lcVariant := JToken.AsValue().AsText();
                if lcVariant <> '' then begin
                    LocItemVariantRegistration.Reset();
                    LocItemVariantRegistration.SETFILTER("Item No.", '%1', TempTransfLine."Item No.");
                    LocItemVariantRegistration.SETFILTER("Variant Dimension 1", '%1', lcVariant);
                    if NOT LocItemVariantRegistration.FindSet() then
                        LocItemVariantRegistration.Init();
                    TempTransfLine."Variant Code" := LocItemVariantRegistration.Variant;
                end;
                if JObjectData.Get('TransfL_Qty', JToken) then
                    TempTransfLine.Quantity := JToken.AsValue().AsDecimal();
                if JObjectData.Get('TransfL_UM', JToken) then
                    TempTransfLine."Unit of Measure Code" := CopyStr(JToken.AsValue().AsCode(), 1, 10);
                if JObjectData.Get('TransfL_Serial', JToken) then
                    TempTransfLine."BPC.Serial No." := CopyStr(JToken.AsValue().AsCode(), 1, 50);
                TempTransfLine."BPC.Interface" := true;
                TempTransfLine."BPC.Active" := true;
                // Serial ++
                //IF FuncCenter.GetValueEnpty(2, FORMAT(JObjectData.GetValue('TransfL_Serial'))) <> '' then begin
                if JObjectData.Get('TransfL_Serial', JToken) then
                    // Serial Not Positive
                    FOR i := 1 TO 2 do begin
                        if i = 1 then
                            Sign := -1
                        else
                            Sign := 1;

                        EntryNo += 1;
                        TempReservEntry.Init();
                        TempReservEntry."Entry No." := EntryNo;
                        TempReservEntry."Item No." := TempTransfLine."Item No.";
                        TempReservEntry."Location Code" := TempTransfLine."BPC.Location Code";
                        TempReservEntry."Source ID" := TempTransfLine."Document No.";
                        TempReservEntry."Source Type" := DATABASE::"Transfer Line";
                        TempReservEntry."Source Ref. No." := TempTransfLine."Line No.";
                        if JObjectData.Get('TransfL_Serial', JToken) then
                            TempReservEntry."Serial No." := CopyStr(JToken.AsValue().AsCode(), 1, 50);
                        //TempReservEntry."Serial No." := FuncCenter.GetValueEnpty(2, FORMAT(JObjectData.GetValue('TransfL_Serial')));
                        TempReservEntry."Variant Code" := TempTransfLine."Variant Code";
                        TempReservEntry.Quantity := 1 * Sign;
                        TempReservEntry."Quantity (Base)" := 1 * Sign;
                        TempReservEntry."Qty. to Handle (Base)" := 1 * Sign;
                        TempReservEntry."Qty. to Invoice (Base)" := 1 * Sign;
                        if i = 1 then
                            TempReservEntry."Source Subtype" := TempReservEntry."Source Subtype"::"0"
                        else
                            TempReservEntry."Source Subtype" := TempReservEntry."Source Subtype"::"1";
                        TempReservEntry.Positive := (Sign = 1);
                        TempReservEntry."Qty. per Unit of Measure" := 1;
                        TempReservEntry."Reservation Status" := TempReservEntry."Reservation Status"::Surplus;
                        TempReservEntry."Item Tracking" := TempReservEntry."Item Tracking"::"Serial No.";
                        TempReservEntry."Shipment Date" := TransfHeader."Posting Date";
                        TempReservEntry."Creation Date" := WorkDate();
                        TempReservEntry."Created By" := CopyStr(UserId(), 1, 50);
                        TempReservEntry.Insert();
                    end;
            end;
            // Serial --
            TempTransfLine.Insert();
        end;
        Window.Close();
    end;

    //end;

    local procedure InsertTransfOrder(IsGenHeader: Boolean; pStoreNo: Code[10])
    var
        TransfHeader: Record "Transfer Header";
        TransfLine: Record "Transfer Line";
        Item: Record Item;
        Status_Var: Option Open,Released,"Pending Approval","Pending Prepayment";
        TransitLoc: Record Location;
    begin
        Window.OPEN('Insert Transfer No. #1############################');
        if IsGenHeader then begin
            TempTransfHeader.Reset();
            if TempTransfHeader.FindSet() then begin
                // Clear Active ++
                TransfHeader.Reset();
                TransfHeader.SetRange("LSC Store-from", pStoreNo);
                TransfHeader.SetRange("BPC.Active", TRUE);
                if TransfHeader.FindSet() then
                    TransfHeader.ModifyAll("BPC.Active", FALSE);
                // Clear Active --
                repeat
                    Window.Update(1, TempTransfHeader."No.");
                    TransfHeader.Reset();
                    TransfHeader.SetRange("No.", TempTransfHeader."No.");
                    if NOT TransfHeader.FINDFIRST then begin
                        // INSERT
                        TransfHeader.Init();
                        TransfHeader.TransferFields(TempTransfHeader);
                        TransfHeader.SetHideValidationDialog(TRUE);
                        TransfHeader.Insert();
                        TransfHeader.Validate("Posting Date", TempTransfHeader."Posting Date");
                        TransfHeader.Validate("Shipment Date", TempTransfHeader."Posting Date");
                        TransfHeader.Validate("Receipt Date", TempTransfHeader."Posting Date");
                        TransfHeader.Validate("Transfer-from Code", TempTransfHeader."Transfer-from Code");
                        TransfHeader.Validate("LSC Store-from", BOUtils.LocationToStore(TransfHeader."Transfer-from Code"));
                        TransfHeader.Validate("Transfer-to Code", TempTransfHeader."Transfer-to Code");
                        TransfHeader.Validate("LSC Store-to", BOUtils.LocationToStore(TransfHeader."Transfer-to Code"));
                        if TempTransfHeader."In-Transit Code" <> '' then begin
                            TransitLoc.Reset();
                            TransitLoc.SetRange("Use As In-Transit", TRUE);
                            TransitLoc.SetRange(Code, TempTransfHeader."In-Transit Code");
                            if TransitLoc.FindSet() then
                                TransfHeader.Validate("In-Transit Code", TempTransfHeader."In-Transit Code")
                            else begin
                                TransitLoc.Reset();
                                TransitLoc.SetRange("Use As In-Transit", TRUE);
                                TransitLoc.FindFirst();
                                TransfHeader.Validate("In-Transit Code", TransitLoc.Code);
                            end;
                        end;
                        TransfHeader."BPC.Retail Status" := TransfHeader."BPC.Retail Status"::Approved;
                        TransfHeader.Status := TransfHeader.Status::Released;
                        TransfHeader.Modify();
                    end else begin
                        // MODIFY
                        Status_Var := TransfHeader.Status;
                        TransfHeader.Status := TransfHeader.Status::Open;
                        TransfHeader.SetHideValidationDialog(TRUE);
                        if TempTransfHeader."In-Transit Code" <> '' then begin
                            //TransfHeader.Validate("In-Transit Code",TempTransfHeader."In-Transit Code");
                            TransitLoc.Reset();
                            TransitLoc.SetRange("Use As In-Transit", TRUE);
                            TransitLoc.SetRange(Code, TempTransfHeader."In-Transit Code");
                            if TransitLoc.FindSet() then
                                TransfHeader.Validate("In-Transit Code", TempTransfHeader."In-Transit Code")
                            else begin
                                TransitLoc.Reset();
                                TransitLoc.SetRange("Use As In-Transit", TRUE);
                                TransitLoc.FindFirst();
                                TransfHeader.Validate("In-Transit Code", TransitLoc.Code);
                            end;
                        end;
                        TransfHeader."Posting Date" := TempTransfHeader."Posting Date";
                        TransfHeader."BPC.Active" := TempTransfHeader."BPC.Active";
                        TransfHeader.Status := Status_Var;
                        TransfHeader.Modify();
                    end;
                until TempTransfHeader.Next() = 0;
            end;
        end else begin
            Clear(JsonUtil);
            TempTransfLine.Reset();
            if TempTransfLine.FindSet() then begin
                // Clear Active ++
                TransfLine.Reset();
                TransfLine.SetRange("Document No.", TempTransfLine."Document No.");
                TransfLine.SetRange("BPC.Active", TRUE);
                if TransfLine.FindSet() then
                    TransfLine.ModifyAll("BPC.Active", FALSE);
                // Clear Active --
                JsonUtil.StartJSon();
                repeat
                    if NOT TransfLine.Get(TempTransfLine."Document No.", TempTransfLine."Line No.") then begin
                        Window.Update(1, TempTransfLine."Document No.");
                        TransfLine.Init();
                        TransfLine.TransferFields(TempTransfLine);
                        TransfLine.Insert();
                        TransfLine.Validate("Item No.", TempTransfLine."Item No.");
                        TransfLine.Validate("BPC.Location Code", TempTransfLine."BPC.Location Code");
                        TransfLine.Validate("Variant Code", TempTransfLine."Variant Code");
                        TransfLine.Validate("In-Transit Code", TempTransfLine."In-Transit Code");
                        TransfLine.Validate("Unit of Measure Code", TempTransfLine."Unit of Measure Code");
                        TransfLine.Validate(Quantity, TempTransfLine.Quantity);
                        TransfLine.Validate("BPC.Serial No.", TempTransfLine."BPC.Serial No.");
                        TransfLine."BPC.Active" := TempTransfLine."BPC.Active";
                        TransfLine.Modify();
                    end else begin
                        TransfLine.Validate("Variant Code", TempTransfLine."Variant Code");
                        TransfLine.Validate("In-Transit Code", TempTransfLine."In-Transit Code");
                        TransfLine.Validate(Quantity, TempTransfLine.Quantity);
                        TransfLine."BPC.Active" := TempTransfLine."BPC.Active";
                        TransfLine.Modify();
                    end;
                    // Serial ++
                    TempReservEntry.Reset();
                    TempReservEntry.SetRange("Source ID", TransfLine."Document No.");
                    TempReservEntry.SetRange("Item No.", TransfLine."Item No.");
                    TempReservEntry.SetRange("Location Code", TransfLine."Transfer-from Code");
                    TempReservEntry.SetRange("Source Type", DATABASE::"Transfer Line");
                    TempReservEntry.SetRange("Source Ref. No.", TransfLine."Line No.");
                    if TempReservEntry.FindFirst() then begin
                        ReservEntry.Reset();
                        ReservEntry.SetRange("Source ID", TransfLine."Document No.");
                        ReservEntry.SetRange("Item No.", TransfLine."Item No.");
                        ReservEntry.SetRange("Location Code", TransfLine."Transfer-from Code");
                        ReservEntry.SetRange("Source Type", DATABASE::"Transfer Line");
                        ReservEntry.SetRange("Source Ref. No.", TransfLine."Line No.");
                        ReservEntry.DeleteAll();
                        repeat
                            ReservEntry.Init();
                            ReservEntry.TransferFields(TempReservEntry);
                            ReservEntry."Entry No." := ReservEntry.GetEntryNo();
                            ReservEntry.Insert();
                        until TempReservEntry.Next() = 0;
                    end;
                // Serial --
                until TempTransfLine.Next() = 0;
                // Delete Line ++
                TransfLine.Reset();
                TransfLine.SetRange("Document No.", TempTransfLine."Document No.");
                TransfLine.SetRange("BPC.Active", FALSE);
                if TransfLine.FindSet() then
                    TransfLine.DeleteAll();
                // Delete Line --
                JsonUtil.EndJSon();
            end;
        end;
        Window.Close();
        Commit();
    end;

    local procedure SummaryTransSalesByStmt(pStmtNo: Code[20]; VAR pTmpSalesEntry: Record "LSC Trans. Sales Entry" TEMPORARY; VAR pRoundingAmt: Decimal; VAR pVAT7Base: Decimal; VAR pVAT0Base: Decimal; VAR pVATAmt: Decimal)
    var
        TransSalesEntryStatus: Record "LSC Trans. Sales Entry Status";
        SalesEntry: Record "LSC Trans. Sales Entry";
        TransactionStatus: Record "LSC Transaction Status";
        TransHeader: Record "LSC Transaction Header";
        TransPayEntry: Record "LSC Trans. Payment Entry";
        PostedStmtLine: Record "LSC Posted Statement Line";
        PaymentEntry: Record "LSC Trans. Payment Entry";
        TransPaymentEntry: Record "LSC Trans. Payment Entry";
        LSCTenderTypeSetup: record "LSC Tender Type Setup";
        LSCTransIncExpEntry: Record "LSC Trans. Inc./Exp. Entry";
        LineNo: Integer;
        POSDataEntry: Record "LSC POS Data Entry";
        SalesEntry2: Record "LSC Trans. Sales Entry";
        LSCTransSalesEntry: Record "LSC Trans. Sales Entry";
    begin
        pTmpSalesEntry.Reset();
        pTmpSalesEntry.DeleteAll();
        Clear(pRoundingAmt);
        Clear(pVAT0Base);
        Clear(pVAT7Base);
        Clear(pVATAmt);
        Clear(LineNo);

        TransSalesEntryStatus.Reset();
        TransSalesEntryStatus.SetRange("Statement No.", pStmtNo);
        if TransSalesEntryStatus.FindSet() then
            repeat
                //SalesEntry
                if NOT SalesEntry.Get(TransSalesEntryStatus."Store No.", TransSalesEntryStatus."POS Terminal No.", TransSalesEntryStatus."Transaction No.", TransSalesEntryStatus."Line No.") then
                    SalesEntry.Init();

                if not SkipReceiptVoidJournal(TransSalesEntryStatus."Store No.", TransSalesEntryStatus."POS Terminal No.", TransSalesEntryStatus."Transaction No.") then begin

                    TransPaymentEntry.Reset();
                    TransPaymentEntry.SetRange("Store No.", TransSalesEntryStatus."Store No.");
                    TransPaymentEntry.SetRange("POS Terminal No.", TransSalesEntryStatus."POS Terminal No.");
                    TransPaymentEntry.SetRange("Transaction No.", TransSalesEntryStatus."Transaction No.");
                    TransPaymentEntry.SetRange("Receipt No.", SalesEntry."Receipt No.");
                    if not TransPaymentEntry.FindSet() then
                        TransPaymentEntry.Init();

                    if not LSCTenderTypeSetup.Get(TransPaymentEntry."Tender Type") then
                        LSCTenderTypeSetup.Init();

                    if not LSCTenderTypeSetup."BPC.Platform"
                        and not (IsDepositUsed(TransSalesEntryStatus."Store No.", TransSalesEntryStatus."POS Terminal No.", TransSalesEntryStatus."Transaction No.")) then begin
                        // if not LSCTenderTypeSetup."BPC.Platform" then begin

                        pTmpSalesEntry.Reset();
                        pTmpSalesEntry.SetRange("Store No.", TransSalesEntryStatus."Store No.");
                        pTmpSalesEntry.SetRange("Transaction No.", TransSalesEntryStatus."Transaction No.");

                        //--A-- 2024/11/15 ++ กรณีเป็น Item Deposit ไม่ต้อง Group
                        if TransSalesEntryStatus."Item No." = 'DS' then
                            pTmpSalesEntry.SetRange("Line No.", TransSalesEntryStatus."Line No.");
                        //--A-- 2024/11/15 --

                        pTmpSalesEntry.SETFILTER("POS Terminal No.", TransSalesEntryStatus."POS Terminal No.");
                        pTmpSalesEntry.SETFILTER("Item No.", TransSalesEntryStatus."Item No.");
                        if NOT pTmpSalesEntry.FindSet() then begin
                            pTmpSalesEntry.Init();
                            pTmpSalesEntry."Store No." := TransSalesEntryStatus."Store No.";
                            pTmpSalesEntry."POS Terminal No." := TransSalesEntryStatus."POS Terminal No.";
                            pTmpSalesEntry."Transaction No." := TransSalesEntryStatus."Transaction No.";
                            pTmpSalesEntry."Line No." := TransSalesEntryStatus."Line No.";
                            pTmpSalesEntry."BPC.Line No. Text" := StrSubstNo('%1', format(TransSalesEntryStatus."Line No."));
                            pTmpSalesEntry."Item No." := TransSalesEntryStatus."Item No.";
                            pTmpSalesEntry."Variant Code" := TransSalesEntryStatus."Variant Code";
                            pTmpSalesEntry."Lot No." := TransSalesEntryStatus."Lot No.";
                            pTmpSalesEntry."Serial No." := TransSalesEntryStatus."Serial No.";
                            pTmpSalesEntry."Sales Type" := SalesEntry."Sales Type";
                            pTmpSalesEntry."BPC.Sales Location" := SalesEntry."BPC.Sales Location";
                            pTmpSalesEntry.Quantity := TransSalesEntryStatus.Quantity;
                            pTmpSalesEntry."Net Amount" := SalesEntry."Net Amount";
                            pTmpSalesEntry."VAT Amount" := SalesEntry."VAT Amount";
                            if TransSalesEntryStatus."Item No." = 'DS' then
                                pTmpSalesEntry."Deal Line" := true
                            else
                                pTmpSalesEntry."Deal Line" := false;
                            pTmpSalesEntry.Insert();
                        end else begin
                            pTmpSalesEntry."BPC.Line No. Text" += StrSubstNo('|%1', format(TransSalesEntryStatus."Line No."));
                            pTmpSalesEntry.Quantity += TransSalesEntryStatus.Quantity;
                            pTmpSalesEntry."Net Amount" += SalesEntry."Net Amount";
                            pTmpSalesEntry."VAT Amount" += SalesEntry."VAT Amount";
                            pTmpSalesEntry.MODIFY;
                        end;

                        pVATAmt += SalesEntry."VAT Amount";
                        if SalesEntry."VAT Amount" = 0 then
                            pVAT0Base += SalesEntry."Net Amount"
                        else
                            pVAT7Base += SalesEntry."Net Amount";
                    end;
                end;

            until TransSalesEntryStatus.Next() = 0;

        TransSalesEntryStatus.Reset();
        TransSalesEntryStatus.SetRange("Statement No.", pStmtNo);
        if TransSalesEntryStatus.FindSet() then
            repeat
                if IsDepositUsed(TransSalesEntryStatus."Store No.", TransSalesEntryStatus."POS Terminal No.", TransSalesEntryStatus."Transaction No.") then begin

                    if not TransHeader.Get(TransSalesEntryStatus."Store No.", TransSalesEntryStatus."POS Terminal No.", TransSalesEntryStatus."Transaction No.") then
                        TransHeader.Init();

                    if not SkipReceiptVoidJournal(TransHeader."Store No.", TransHeader."POS Terminal No.", TransHeader."Transaction No.") then begin

                        LSCTransSalesEntry.Reset();
                        LSCTransSalesEntry.SetRange("Store No.", TransHeader."Store No.");
                        LSCTransSalesEntry.SetRange("POS Terminal No.", TransHeader."POS Terminal No.");
                        LSCTransSalesEntry.SetRange("Receipt No.", TransHeader."Receipt No.");
                        LSCTransSalesEntry.SetRange("Transaction No.", TransHeader."Transaction No.");
                        if LSCTransSalesEntry.FindSet() then begin
                            pTmpSalesEntry.Reset();
                            pTmpSalesEntry.SetRange("Store No.", TransHeader."Store No.");
                            pTmpSalesEntry.SetRange("POS Terminal No.", TransHeader."POS Terminal No.");
                            pTmpSalesEntry.SetRange("Transaction No.", TransHeader."Transaction No.");
                            pTmpSalesEntry.SetRange("Item No.", LSCTransSalesEntry."Item No.");
                            if pTmpSalesEntry.FindLast() then
                                LineNo := pTmpSalesEntry."Line No.";

                            repeat
                                SalesEntry2.Reset();
                                SalesEntry2.SetRange("Receipt No.", LSCTransSalesEntry."Receipt No.");
                                SalesEntry2.SetRange("Item No.", LSCTransSalesEntry."Item No.");
                                if not SalesEntry2.FindSet() then
                                    SalesEntry2.Init()
                                else
                                    SalesEntry2.CalcSums("Net Amount", "VAT Amount");

                                pTmpSalesEntry.Reset();
                                pTmpSalesEntry.SetRange("Store No.", TransHeader."Store No.");
                                pTmpSalesEntry.SetRange("POS Terminal No.", TransHeader."POS Terminal No.");
                                pTmpSalesEntry.SetRange("Transaction No.", TransHeader."Transaction No.");
                                pTmpSalesEntry.SetRange("Item No.", LSCTransSalesEntry."Item No.");
                                if not pTmpSalesEntry.FindLast() then begin
                                    LineNo += 10000;
                                    pTmpSalesEntry.Init();
                                    pTmpSalesEntry."Store No." := TransHeader."Store No.";
                                    pTmpSalesEntry."POS Terminal No." := TransHeader."POS Terminal No.";
                                    pTmpSalesEntry."Transaction No." := TransHeader."Transaction No.";
                                    pTmpSalesEntry."Line No." := LineNo;
                                    pTmpSalesEntry."BPC.Line No. Text" := StrSubstNo('%1', format(LineNo));
                                    pTmpSalesEntry."Item No." := LSCTransSalesEntry."Item No.";
                                    // pTmpSalesEntry."Net Amount" := -(POSDataEntry.Amount - Round((POSDataEntry.Amount * 7) / 107, 0.01, '='));
                                    // pTmpSalesEntry."VAT Amount" := -Round((POSDataEntry.Amount * 7) / 107, 0.01, '=');
                                    pTmpSalesEntry."Net Amount" := SalesEntry2."Net Amount";
                                    pTmpSalesEntry."VAT Amount" := SalesEntry2."VAT Amount";
                                    pTmpSalesEntry."Tot. Disc Info Line No." := POSDataEntry."Applied by Line No."; ///ฝากเป็นขาใช้ DEPOSIT LineNo. IncExp
                                    pTmpSalesEntry.Insert();

                                    pVATAmt += SalesEntry2."VAT Amount";
                                    if SalesEntry2."VAT Amount" = 0 then
                                        pVAT0Base += SalesEntry2."Net Amount"
                                    else
                                        pVAT7Base += SalesEntry2."Net Amount";
                                end;

                            until LSCTransSalesEntry.Next() = 0;
                        end;

                        //เสือ
                        // POSDataEntry.Reset();
                        // POSDataEntry.SetRange("Applied by Receipt No.", TransHeader."Receipt No.");
                        // POSDataEntry.SetRange("Entry Type", 'DEPOSIT');
                        // if POSDataEntry.FindSet() then begin

                        //     pTmpSalesEntry.Reset();
                        //     pTmpSalesEntry.SetRange("Store No.", TransHeader."Store No.");
                        //     pTmpSalesEntry.SetRange("POS Terminal No.", TransHeader."POS Terminal No.");
                        //     pTmpSalesEntry.SetRange("Transaction No.", TransHeader."Transaction No.");
                        //     if pTmpSalesEntry.FindLast() then
                        //         LineNo := pTmpSalesEntry."Line No.";

                        //     repeat
                        //         SalesEntry2.Reset();
                        //         SalesEntry2.SetRange("Receipt No.", POSDataEntry."Applied by Receipt No.");
                        //         SalesEntry2.SetRange("Item No.", POSDataEntry."BPC.Item No.");
                        //         if not SalesEntry2.FindSet() then
                        //             SalesEntry2.Init()
                        //         else
                        //             SalesEntry2.CalcSums("Net Amount", "VAT Amount");

                        //         pTmpSalesEntry.Reset();
                        //         pTmpSalesEntry.SetRange("Store No.", TransHeader."Store No.");
                        //         pTmpSalesEntry.SetRange("POS Terminal No.", TransHeader."POS Terminal No.");
                        //         pTmpSalesEntry.SetRange("Transaction No.", TransHeader."Transaction No.");
                        //         pTmpSalesEntry.SetRange("Item No.", POSDataEntry."BPC.Item No.");
                        //         if not pTmpSalesEntry.FindLast() then begin
                        //             LineNo += 10000;
                        //             pTmpSalesEntry.Init();
                        //             pTmpSalesEntry."Store No." := TransHeader."Store No.";
                        //             pTmpSalesEntry."POS Terminal No." := TransHeader."POS Terminal No.";
                        //             pTmpSalesEntry."Transaction No." := TransHeader."Transaction No.";
                        //             pTmpSalesEntry."Line No." := LineNo;
                        //             pTmpSalesEntry."BPC.Line No. Text" := StrSubstNo('%1', format(LineNo));
                        //             pTmpSalesEntry."Item No." := POSDataEntry."BPC.Item No.";
                        //             // pTmpSalesEntry."Net Amount" := -(POSDataEntry.Amount - Round((POSDataEntry.Amount * 7) / 107, 0.01, '='));
                        //             // pTmpSalesEntry."VAT Amount" := -Round((POSDataEntry.Amount * 7) / 107, 0.01, '=');
                        //             pTmpSalesEntry."Net Amount" := SalesEntry2."Net Amount";
                        //             pTmpSalesEntry."VAT Amount" := SalesEntry2."VAT Amount";
                        //             pTmpSalesEntry."Tot. Disc Info Line No." := POSDataEntry."Applied by Line No."; ///ฝากเป็นขาใช้ DEPOSIT LineNo. IncExp
                        //             pTmpSalesEntry.Insert();

                        //             pVATAmt += SalesEntry2."VAT Amount";
                        //             if SalesEntry2."VAT Amount" = 0 then
                        //                 pVAT0Base += SalesEntry2."Net Amount"
                        //             else
                        //                 pVAT7Base += SalesEntry2."Net Amount";
                        //         end;
                        //     until POSDataEntry.Next() = 0;
                        // end;
                        //เสือ
                    end;
                end;
            until TransSalesEntryStatus.Next() = 0;

        //--A-- 2023/06/28
        //Clear(pVATAmt); //--A--
        PostedStmtLine.Reset();
        PostedStmtLine.SetRange("Statement No.", pStmtNo);
        PostedStmtLine.SetRange("Tender Type", '14.00');
        if PostedStmtLine.FindSet() then begin
            TransactionStatus.Reset();
            TransactionStatus.SetRange("Store No.", PostedStmtLine."Store No.");
            TransactionStatus.SetRange("POS Terminal No.", PostedStmtLine."POS Terminal No.");
            TransactionStatus.SetRange("Statement No.", PostedStmtLine."Statement No.");
            TransactionStatus.SetRange(Status, TransactionStatus.Status::Posted);
            if TransactionStatus.FindSet() then begin
                repeat
                    TransPayEntry.Reset();
                    TransPayEntry.SetRange("Store No.", PostedStmtLine."Store No.");
                    TransPayEntry.SetRange("POS Terminal No.", PostedStmtLine."POS Terminal No.");
                    TransPayEntry.SetRange("Tender Type", PostedStmtLine."Tender Type");
                    TransPayEntry.SetRange("Transaction No.", TransactionStatus."Transaction No.");
                    if TransPayEntry.FindSet() then
                        repeat
                            pVATAmt += TransPayEntry."BPC.POS VAT Amount";
                        //pVATAmt += TransactionStatus."VAT Amount" + TransPayEntry."POS VAT Amount"; //--A--
                        until TransPayEntry.Next() = 0;
                until TransactionStatus.Next() = 0;
            end;
        end;
        //--A-- 2023/06/28
        //DRL - Deposit VAT

        // GetNetAmtAndVatAmt(TransSalesEntryStatus."Store No.",
        //                     TransSalesEntryStatus."POS Terminal No.",
        //                     TransSalesEntryStatus."Transaction No.",
        //                     pVAT7Base, pVATAmt);

        TransactionStatus.Reset();
        TransactionStatus.SetRange("Posted Statement No.", pStmtNo);
        if TransactionStatus.FindSet() then
            repeat
                if TransHeader.Get(TransactionStatus."Store No.", TransactionStatus."POS Terminal No.", TransactionStatus."Transaction No.") then begin
                    pRoundingAmt += TransHeader.Rounded;
                end;
            until TransactionStatus.Next() = 0;
    end;

    procedure GetJnlDocID(var pJnlDocID: Code[20])
    begin
        pJnlDocID := JnlDocID_g;
    end;

    local procedure "------------Other------------"()
    begin
    end;

    procedure CallAPIService_POST(pFunctionsName: Text; pJsonRequestStr: Text; var pAPIResult: Text; DocumentNoLog: Text): Boolean
    var
        HttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
        //: Record "BPC.TempBlob" temporary;
        InStr: InStream;
        LocAPIResult: Text;
        URL: Text;
        UserName: Text;
        Password: Text;
        AuthString: Text;
        Base64Convert: Codeunit 4110;
        RequestMessage: HttpRequestMessage;
        RequestHeaders: HttpHeaders;
        HttpHeadersContent: HttpHeaders;
        FOTenantID: Text;
        Content: HttpContent;
        ResponseStream: InStream;
        TempBlob: Codeunit "Temp Blob";
        ResponseMessage: HttpResponseMessage;
        IsSuccessful: Boolean;
        Client: HttpClient;
        StatusCode: Text;
        APICallResponseMessage: Text;
    begin
        Clear(HttpWebRequestMgt);
        if pFunctionsName = 'TestCallAPI' then
            URL := pFunctionsName
        else
            URL := GetURLInterface(pFunctionsName);

        // UserName := RetailSetup."BPC.Interface User Name";
        // Password := RetailSetup."BPC.Interface Password";
        //FOTenantID := RetailSetup."BPC.Interface Tenant ID";
        // AuthString := StrSubstNo('%1:%2', UserName, Password);
        //AuthString := Base64Convert.ToBase64(AuthString);
        // AuthString := StrSubstNo('Basic %1', AuthString);

        RequestMessage.GetHeaders(RequestHeaders);
        RequestHeaders.Clear();
        RequestHeaders.Add('Authorization', 'Bearer ' + GetToken);
        // RequestHeaders.Add('Authorization', AuthString);
        //  RequestHeaders.Add('Accept', 'application/xml');
        Content.WriteFrom(pJsonRequestStr);

        //GET HEADERS
        Content.GetHeaders(HttpHeadersContent);
        HttpHeadersContent.Clear();
        //HttpHeadersContent.Remove('Content-Type');//
        //HttpHeadersContent.Add('Content-Type', 'text/xml');

        //POST METHOD
        RequestMessage.Content := Content;
        RequestMessage.SetRequestUri(URL);
        // RequestMessage.SetRequestUri(FOTenantID);
        RequestMessage.Method := 'POST';

        // Clear(TempBlob);
        // TempBlob.CreateInStream(ResponseStream);

        // Client.Send(RequestMessage, ResponseMessage);
        // InsertInterfaceLog(pFunctionsName, pJsonRequestStr, URL, pAPIResult, DocumentNoLog, FALSE); // เก็บ Log

        IsSuccessful := Client.Send(RequestMessage, ResponseMessage);


        if not IsSuccessful then begin
            InsertInterfaceLog(pFunctionsName, pJsonRequestStr, URL, GETLASTERRORTEXT, DocumentNoLog, TRUE); // เก็บ Log ERROR
            EXIT(FALSE)
        end;
        if not ResponseMessage.IsSuccessStatusCode() then begin
            StatusCode := Format(ResponseMessage.HttpStatusCode()) + ' - ' + ResponseMessage.ReasonPhrase;
            ResponseMessage.Content.ReadAs(APICallResponseMessage);
            InsertInterfaceLog(pFunctionsName, pJsonRequestStr, URL, APICallResponseMessage, DocumentNoLog, TRUE); // เก็บ Log ERROR
            EXIT(FALSE)
        end;
        if not ResponseMessage.Content().ReadAs(ResponseStream) then begin
            InsertInterfaceLog(pFunctionsName, pJsonRequestStr, URL, GETLASTERRORTEXT, DocumentNoLog, TRUE); // เก็บ Log ERROR
            EXIT(FALSE)
        end else begin
            ResponseMessage.Content().ReadAs(APICallResponseMessage);
            pAPIResult := APICallResponseMessage;
            InsertInterfaceLog(pFunctionsName, pJsonRequestStr, URL, pAPIResult, DocumentNoLog, FALSE); // เก็บ Log
            EXIT(true);
        end;

    end;

    procedure GetToken(): Text
    var
        HttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
        JSONMgt: Codeunit "JSON Management";
        HttpRequestMessage: HttpRequestMessage;
        TempBlob: Record "BPC.TempBlob" temporary;
        InStr: InStream;
        // UserName: Text;
        // Password: Text;
        ClientID: Text;
        ClientSecret: Text;
        Resource: Text;
        FOTenantID: Text;
        PostToken: Text;
        AccessToken: Text;
        URLToken: Text;
        HttpContent: HttpContent;
        HttpHeaders: HttpHeaders;
        HttpClient: HttpClient;
        HttpResponseMessage: HttpResponseMessage;
        ResponseText: Text;
        JsonObject: JsonObject;
        JsonToken: JsonToken;
        JsonValue: JsonValue;
    begin

        Clear(HttpWebRequestMgt);
        Clear(AccessToken);
        URLToken := 'https://login.microsoftonline.com/common/oauth2/token';
        // UserName := RetailSetup."BPC.Interface User Name";
        // Password := RetailSetup."BPC.Interface Password";
        ClientID := RetailSetup."BPC.Interface ClientID";
        ClientSecret := RetailSetup."BPC.Interface Client Secret";
        FOTenantID := RetailSetup."BPC.Interface Tenant ID";
        if FOTenantID <> '' then
            URLToken := StrSubstNo('https://login.microsoftonline.com/%1/oauth2/token', FOTenantID);
        Resource := RetailSetup."BPC.Interface Resource";
        if CheckTokenExpire(AccessToken) then begin
            // if FOTenantID = '' then
            //     PostToken := StrSubstNo('grant_type=password&username=%1&password=%2&client_id=%3&client_secret=%4&resource=%5',
            //                            UserName, Password, ClientID, ClientSecret, Resource)
            // else
            PostToken := StrSubstNo('grant_type=client_credentials&client_id=%1&client_secret=%2&resource=%3',
                                   ClientID, ClientSecret, Resource);
            HttpContent.WriteFrom(PostToken);
            //HttpWebRequestMgt.Initialize(URLToken);
            //HttpWebRequestMgt.DisableUI;
            HttpContent.GetHeaders(HttpHeaders);
            HttpHeaders.Clear();
            HttpHeaders.Add('Content-Type', 'application/x-www-form-urlencoded');

            HttpRequestMessage.Content := HttpContent;

            HttpRequestMessage.SetRequestUri(URLToken);
            HttpRequestMessage.Method := 'POST';
            // HttpWebRequestMgt.SetMethod('POST');
            // HttpWebRequestMgt.SetContentType('application/x-www-form-urlencoded');
            // HttpWebRequestMgt.SetContentLength(STRLEN(PostToken));
            HttpClient.Send(HttpRequestMessage, HttpResponseMessage);

            if not HttpResponseMessage.IsSuccessStatusCode() then begin
                InsertInterfaceLog('GetToken', PostToken, URLToken, GETLASTERRORTEXT, '', FALSE);  // เก็บ Log 
            end;

            HttpResponseMessage.Content().ReadAs(ResponseText);
            if not JsonObject.ReadFrom(ResponseText) then begin
                InsertInterfaceLog('GetToken', PostToken, URLToken, GETLASTERRORTEXT, '', FALSE);  // เก็บ Log 
            end;

            if not JsonObject.Contains('access_token') then begin
                InsertInterfaceLog('GetToken', PostToken, URLToken, GETLASTERRORTEXT, '', FALSE);  // เก็บ Log
            end else begin
                JsonObject.Get('access_token', JsonToken);
                JsonValue := JsonToken.AsValue();
                JsonToken.WriteTo(AccessToken);
                AccessToken := DelChr(AccessToken, '<>', '"');
            end;
        end;
        EXIT(AccessToken);
    end;

    local procedure CheckTokenExpire(var AccessToken: Text): Boolean
    var
        InterfaceLogDRL: Record "BPC.Interface Log API";
        InterfaceDate: Duration;
        IntHours: Integer;
        IntMin: Integer;
    begin
        InterfaceLogDRL.Reset();
        InterfaceLogDRL.SETFILTER("BPC.Interface Type", '%1', 'Token');
        InterfaceLogDRL.SETFILTER("BPC.Document No.", '%1', 'T0001');
        if InterfaceLogDRL.FINDFIRST then begin
            InterfaceDate := CREATEDATETIME(TODAY, TIME) - InterfaceLogDRL."BPC.Interface DateTime";
            IntHours := (InterfaceDate DIV (60 * 60 * 1000));
            IntMin := ((InterfaceDate MOD (60 * 60 * 1000)) DIV (60 * 1000)) + (IntHours * 60);
            if IntMin <= 55 then
                AccessToken := InterfaceLogDRL.GetD365Response(TEXTENCODING::UTF8);
        end;
        EXIT(AccessToken = '')
    end;

    local procedure GetURLInterface(Var pFunctionsName: Text) URL: Text
    begin
        RetailSetup.Get();
        APIConfiguration.Get();
        case pFunctionsName of
            'GetPurchaseHeader':
                URL := StrSubstNo('%1%2', RetailSetup."BPC.Interface Resource", APIConfiguration.GetPurchaseHeader);
            'GetPurchaseLine':
                URL := StrSubstNo('%1%2', RetailSetup."BPC.Interface Resource", APIConfiguration.GetPurchaseLine);
            'GetSalesHeader':
                URL := StrSubstNo('%1%2', RetailSetup."BPC.Interface Resource", APIConfiguration.GetSalesHeader);
            'GetSalesLine':
                URL := StrSubstNo('%1%2', RetailSetup."BPC.Interface Resource", APIConfiguration.GetSalesLine);
            'GetTransferHeader':
                URL := StrSubstNo('%1%2', RetailSetup."BPC.Interface Resource", APIConfiguration.GetTransferHeader);
            'GetTransferLine':
                URL := StrSubstNo('%1%2', RetailSetup."BPC.Interface Resource", APIConfiguration.GetTransferLine);
            'PostPurchaseReceive':
                URL := StrSubstNo('%1%2', RetailSetup."BPC.Interface Resource", APIConfiguration.PostPurchaseReceive);
            'SendPurchaseReceive':
                URL := StrSubstNo('%1%2', RetailSetup."BPC.Interface Resource", APIConfiguration.SendPurchaseReceive);
            'SendUndoReceipt':
                URL := StrSubstNo('%1%2', RetailSetup."BPC.Interface Resource", APIConfiguration.SendUndoReceipt);
            'PostPurchaseShipment':
                URL := StrSubstNo('%1%2', RetailSetup."BPC.Interface Resource", APIConfiguration.PostPurchaseShipment);
            'PostTransfersShipment':
                URL := StrSubstNo('%1%2', RetailSetup."BPC.Interface Resource", APIConfiguration.PostTransfersShipment);
            'PostTransfersReceipt':
                URL := StrSubstNo('%1%2', RetailSetup."BPC.Interface Resource", APIConfiguration.PostTransfersReceipt);
            'PostTransfersReceiptAuto':
                URL := StrSubstNo('%1%2', RetailSetup."BPC.Interface Resource", APIConfiguration.PostTransfersReceiptAuto);
            'SendCheckSerial':
                URL := StrSubstNo('%1%2', RetailSetup."BPC.Interface Resource", APIConfiguration.SendCheckSerial);
            'SendCheckStock':
                URL := StrSubstNo('%1%2', RetailSetup."BPC.Interface Resource", APIConfiguration.SendCheckStock);
            'CheckSerialExist':
                URL := StrSubstNo('%1%2', RetailSetup."BPC.Interface Resource", APIConfiguration.CheckSerialExist);
            'SendCloseBill':
                URL := StrSubstNo('%1%2', RetailSetup."BPC.Interface Resource", APIConfiguration.SendCloseBill);
            'SendVoidBill':
                URL := StrSubstNo('%1%2', RetailSetup."BPC.Interface Resource", APIConfiguration.SendVoidBill);
            'SendChkInvenLookupInStock':
                URL := StrSubstNo('%1%2', RetailSetup."BPC.Interface Resource", APIConfiguration.SendChkInvenLookupInStock);
            'PostTransferJournal':
                URL := StrSubstNo('%1%2', RetailSetup."BPC.Interface Resource", APIConfiguration.PostTransferJournal);
            'PostInventCountingJournal':
                URL := StrSubstNo('%1%2', RetailSetup."BPC.Interface Resource", APIConfiguration.PostInventCountingJournal);
            'PostInventAdjustJournal':
                URL := StrSubstNo('%1%2', RetailSetup."BPC.Interface Resource", APIConfiguration.PostInventAdjustJournal);
            'APITestConnection':
                URL := StrSubstNo('%1%2', RetailSetup."BPC.Interface Resource", APIConfiguration.APITestConnection);
            'createProduct':
                URL := StrSubstNo('%1%2', RetailSetup."BPC.Interface Resource", APIConfiguration.CreateProduct);
            'postStmtJournal':
                URL := StrSubstNo('%1%2', RetailSetup."BPC.Interface Resource", APIConfiguration.postStmtJournal);
            'postStmtMovement':
                URL := StrSubstNo('%1%2', RetailSetup."BPC.Interface Resource", APIConfiguration.postStmtMovement);
            'getStmtStatus':
                URL := StrSubstNo('%1%2', RetailSetup."BPC.Interface Resource", APIConfiguration.getStmtStatus);
            'getGRNStatus':
                URL := StrSubstNo('%1%2', RetailSetup."BPC.Interface Resource", APIConfiguration.getGRNStatus);
            'getInventTrans':
                URL := StrSubstNo('%1%2', RetailSetup."BPC.Interface Resource", APIConfiguration.getInventTrans);
            'PostSalesShipment':
                URL := StrSubstNo('%1%2', RetailSetup."BPC.Interface Resource", APIConfiguration.PostSalesShipment);
            'PostSalesShipment_POS':
                URL := StrSubstNo('%1%2', RetailSetup."BPC.Interface Resource", APIConfiguration.PostSalesShipment);
            'SendExpense':
                URL := StrSubstNo('%1%2', RetailSetup."BPC.Interface Resource", APIConfiguration.SendExpense);
            'GetItem':
                URL := StrSubstNo('%1%2', RetailSetup."BPC.Interface Resource", APIConfiguration.GetItem);
            'PostItemJournal':
                URL := StrSubstNo('%1%2', RetailSetup."BPC.Interface Resource", APIConfiguration.PostItemJournal);
            'SendUndoShipment':
                URL := StrSubstNo('%1%2', RetailSetup."BPC.Interface Resource", APIConfiguration.SendUndoShipment);

        end;
    end;

    local procedure GetVendorInfor(VendNo: Code[20]; VendorName: Text[100]): Code[20]
    var
        ConfigTemplateMgt: Codeunit "Config. Template Management";
        RecRef: RecordRef;
        ConfigTemplateHeader: Record "Config. Template Header";
        VendorTemplMgt: Codeunit "Vendor Templ. Mgt.";
        VendorTempl: Record "Vendor Templ.";
    begin
        if not VendorTempl.Get('VENDOR') then
            VendorTempl.Init();
        if NOT Vend.Get(VendNo) then begin
            Vend.Init();
            Vend.Validate("No.", VendNo);
            Vend.Validate(Name, VendorName);
            Vend.Validate("Gen. Bus. Posting Group", VendorTempl."Gen. Bus. Posting Group");
            Vend.Validate("Vendor Posting Group", VendorTempl."Vendor Posting Group");
            // Vend."No." := VendNo;
            // Vend.Name := VendorName;
            Vend.INSERT(TRUE);
            // Apply Template
            RecRef.GetTable(Vend);
            ConfigTemplateHeader.SetRange("Table ID", RecRef.NUMBER);
            if ConfigTemplateHeader.FINDFIRST then
                ConfigTemplateMgt.UpdateRecord(ConfigTemplateHeader, RecRef);
            Commit();
        end else begin
            Vend.Name := VendorName;
            Vend.Validate("Gen. Bus. Posting Group", VendorTempl."Gen. Bus. Posting Group");
            Vend.Validate("Vendor Posting Group", VendorTempl."Vendor Posting Group");
            Vend.MODIFY(TRUE);
            Commit();
        end;
        EXIT(VendNo);
    end;

    procedure CreateJsonSendExpense(SelectionFunctions: Text; PurchInvHdrNo: Code[20]): Text
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        VATAmount: Decimal;
    begin
        if SelectionFunctions = 'SendExpense' then begin
            begin
                PurchInvHeader.Reset();
                PurchInvHeader.SETFILTER("No.", PurchInvHdrNo);
                if PurchInvHeader.FindSet() then begin
                    JsonUtil.StartJSon();
                    // Header
                    JsonUtil.AddToJSon('Vendor No.', PurchInvHeader."Buy-from Vendor No.");
                    JsonUtil.AddToJSon('Document No.', PurchInvHeader."No.");
                    JsonUtil.AddToJSon('Document Date', FORMAT(PurchInvHeader."Document Date", 0, '<Year4>-<Month,2>-<Day,2>'));
                    // Line
                    PurchInvLine.Reset();
                    PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
                    if PurchInvLine.FindSet() then begin
                        JsonUtil.StartJSonArray('Expens Line');
                        repeat
                            //if PurchInvLine.Type <> PurchInvLine.Type::" " then begin
                            Clear(VATAmount);
                            JsonUtil.StartJSon();
                            JsonUtil.AddToJSon('Line No.', PurchInvLine."Line No.");
                            JsonUtil.AddToJSon('Item No.', PurchInvLine."No.");
                            JsonUtil.AddToJSon('VAT Prod.', PurchInvLine."VAT Prod. Posting Group");
                            JsonUtil.AddToJSon('Tax Category Code', PurchInvLine."Item Category Code");
                            JsonUtil.AddToJSon('BPC Tax Invoice No.', PurchInvLine."BPC Tax Invoice No.");
                            JsonUtil.AddToJSon('BPC Tax Invoice Date', FORMAT(PurchInvLine."BPC Tax Invoice Date", 0, '<Year4>-<Month,2>-<Day,2>'));
                            JsonUtil.AddToJSon('BPC Tax Invoice Base', PurchInvLine."BPC_Tax Invoice Base");
                            JsonUtil.AddToJSon('Amount Incl. VAT', PurchInvLine."Amount Including VAT");
                            if PurchInvLine."VAT %" = 0 then begin
                                JsonUtil.AddToJSon('VAT_Amount', 0);
                            end else begin
                                VATAmount := (PurchInvLine.Amount * PurchInvLine."VAT %") / 100;
                                JsonUtil.AddToJSon('VAT_Amount', VATAmount);
                            end;
                            JsonUtil.AddToJSon('BPC Tax invoice name', PurchInvLine."BPC Tax Invoice Name");
                            JsonUtil.AddToJSon('BPC Tax Registration', PurchInvLine."BPC Tax Registration No.");
                            JsonUtil.AddToJSon('BPC Tax Head office', PurchInvLine."BPC Tax Head Office");
                            JsonUtil.AddToJSon('BPC Tax Branch No', PurchInvLine."BPC Tax Branch No.");
                            JsonUtil.AddToJSon('Description', PurchInvLine.Description);
                            JsonUtil.EndJSon();
                        //end;
                        until PurchInvLine.Next() = 0;
                        JsonUtil.EndJSonArray;
                    end;
                    JsonUtil.EndJSon();
                end;
            end;
            EXIT(JsonUtil.GetJSon());
        end;
    end;

    local procedure CreateJsonPaymentEntryObject(TransPaymentEntry: Record "LSC Trans. Payment Entry"; VoucherEntriesTmp: Record "BPC.Voucher Entries Tmp")
    var
        POSCardEntry: Record "LSC POS Card Entry";
        VoucherEntries: Record "LSC Voucher Entries";
        VoucherEntries1: Record "LSC Voucher Entries";
        //VoucherEntriesTmp: Record "BPC.Voucher Entries Tmp";
        VoucherNo: TEXT;
        TenderAmount: Decimal;
        TenderAmountBase: Decimal;
        Amount_N: Decimal;
        VoucherEntriesCheck: Record "LSC Voucher Entries";
    begin
        //VoucherEntriesTmp.DeleteAll();
        JsonUtil.StartJSon();
        JsonUtil.AddToJSon('TenderType', TransPaymentEntry."Tender Type");
        JsonUtil.AddToJSon('Amount', TransPaymentEntry."Amount Tendered");
        JsonUtil.AddToJSon('POS_No', TransPaymentEntry."POS Terminal No.");
        JsonUtil.AddToJSon('Transaction_no', TransPaymentEntry."Transaction No.");

        POSCardEntry.Reset();
        POSCardEntry.SetRange("Store No.", TransPaymentEntry."Store No.");
        POSCardEntry.SetRange("POS Terminal No.", TransPaymentEntry."POS Terminal No.");
        POSCardEntry.SetRange("Tender Type", TransPaymentEntry."Tender Type");
        POSCardEntry.SetRange("Transaction No.", TransPaymentEntry."Transaction No.");
        POSCardEntry.SetRange("Line No.", TransPaymentEntry."Line No.");
        if POSCardEntry.FindFirst() then
            JsonUtil.AddToJSon('ApprovalCode', POSCardEntry."BPC Approval Code")
        else
            JsonUtil.AddToJSon('ApprovalCode', '');

        JsonUtil.AddToJSon('Receipt_No', TransPaymentEntry."Receipt No.");

        if TransPaymentEntry."Tender Type" = 'CNRETURN' then begin
            Clear(VoucherNo);
            VoucherEntries.Reset();
            VoucherEntries.SetRange("Voucher Type", 'CN');
            VoucherEntries.SetRange("Receipt Number", TransPaymentEntry."Receipt No.");
            if VoucherEntries.FindSet() then begin
                VoucherNo := VoucherEntries."Voucher No.";
                VoucherEntries1.Reset();
                VoucherEntries1.SetRange("Voucher No.", VoucherNo);
                VoucherEntries1.SetRange("Entry Type", VoucherEntries1."Entry Type"::Issued);
                if VoucherEntries1.FindSet() then begin
                    JsonUtil.AddToJSon('CN_Exchange', VoucherEntries1."Receipt Number");
                end else begin
                    JsonUtil.AddToJSon('CN_Exchange', '');
                end;
            end else begin
                JsonUtil.AddToJSon('CN_Exchange', '');
            end;
        end else begin
            JsonUtil.AddToJSon('CN_Exchange', '');
        end;

        TenderAmount := Abs(TransPaymentEntry."Amount Tendered");
        Amount_N := 0;

        //Deposit CN Exchang
        VoucherEntriesTmp.Reset();
        VoucherEntriesTmp.SetRange("Entry Type", VoucherEntries."Entry Type"::Redemption);
        VoucherEntriesTmp.SetRange("Voucher Type", 'DEPOSIT');
        VoucherEntriesTmp.SetRange("Receipt Number", TransPaymentEntry."Receipt No.");
        VoucherEntriesTmp.SetFilter(Amount, '>0');
        VoucherEntriesTmp.SetFilter("Return Deposit", '1');
        if VoucherEntriesTmp.FindSet() then begin
            JsonUtil.StartJSonArray('Deposit');
            repeat

                if TenderAmount > 0 then begin
                    JsonUtil.StartJSon();
                    JsonUtil.AddToJSon('Deposit_No', VoucherEntriesTmp."Voucher No.");
                    if TenderAmount >= VoucherEntriesTmp.Amount then begin
                        JsonUtil.AddToJSon('Amount', VoucherEntriesTmp.Amount * -1);
                        TenderAmount := TenderAmount - VoucherEntriesTmp.Amount;
                        VoucherEntriesTmp.Amount := 0;
                        VoucherEntriesTmp.Modify();
                    end else begin
                        JsonUtil.AddToJSon('Amount', TenderAmount * -1);
                        VoucherEntriesTmp.Amount := VoucherEntriesTmp.Amount - TenderAmount;
                        TenderAmount := 0;
                        VoucherEntriesTmp.Modify();
                    end;
                    JsonUtil.EndJSon();
                end;
            until VoucherEntriesTmp.next = 0;
            JsonUtil.EndJSonArray;
        end else begin
            //เคส deposit จ่ายหลาย tender type
            VoucherEntriesTmp.Reset();
            VoucherEntriesTmp.SetRange("Entry Type", VoucherEntries."Entry Type"::Issued);
            VoucherEntriesTmp.SetRange("Voucher Type", 'DEPOSIT');
            VoucherEntriesTmp.SetRange("Receipt Number", TransPaymentEntry."Receipt No.");
            VoucherEntriesTmp.SetFilter(Amount, '>0');
            if VoucherEntriesTmp.FindSet() then begin
                JsonUtil.StartJSonArray('Deposit');
                repeat
                    if TenderAmount > 0 then begin
                        JsonUtil.StartJSon();
                        JsonUtil.AddToJSon('Deposit_No', VoucherEntriesTmp."Voucher No.");
                        if TenderAmount >= VoucherEntriesTmp.Amount then begin
                            JsonUtil.AddToJSon('Amount', VoucherEntriesTmp.Amount);
                            TenderAmount := TenderAmount - VoucherEntriesTmp.Amount;
                            VoucherEntriesTmp.Amount := 0;
                            VoucherEntriesTmp.Modify();
                        end else begin
                            JsonUtil.AddToJSon('Amount', TenderAmount);
                            VoucherEntriesTmp.Amount := VoucherEntriesTmp.Amount - TenderAmount;
                            TenderAmount := 0;
                            VoucherEntriesTmp.Modify();
                        end;
                        JsonUtil.EndJSon();
                    end;
                until VoucherEntriesTmp.next = 0;
                JsonUtil.EndJSonArray;
            end else begin
                JsonUtil.AddToJSon('Deposit', '');
            end;
        end;
        JsonUtil.EndJSon();
    end;

    procedure CreateJsonRequestStr(SelectionFunctions: Text; pRecRef: RecordRef): Text
    var
        TransactionStatus: Record "LSC Transaction Status";
        TransPaymentEntry: Record "LSC Trans. Payment Entry";
        TransactionHeader: Record "LSC Transaction Header";
        TransactionHeaderDiff: Record "LSC Transaction Header";
        TransPaymentEntryDiff: Record "LSC Trans. Payment Entry";
        VoucherEntries: Record "LSC Voucher Entries";
        VoucherEntries1: Record "LSC Voucher Entries";
        PostedAssemblyLine: Record "Posted Assembly Line";
        TransaHeader: Record "LSC Transaction Header";
        ItemLedgerEnt: Record "Item Ledger Entry";
        TrackingSpecification: Record "Tracking Specification";
        TransferReceiptHeader: Record "Transfer Receipt Header";
        TransferReceiptLine: Record "Transfer Receipt Line";
        TMPItemLedgEntry: Record "BPC.TMPItemLedgEntry";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        ItemJournalLine: Record "Item Journal Line";
        LSCTransactionHeader: Record "LSC Transaction Header";
        TransSalesEntry: Record "LSC Trans. Sales Entry";
        LedgEntry: Record "Item Ledger Entry";
        BOMLedgEntry: Record "Item Ledger Entry";
        BomList: Record "BOM Component";
        AssembletoOrderLink: Record "Assemble-to-Order Link";
        ItemLedgerEntrySerial: Record "Item Ledger Entry";
        ItemEntryRelation: Record "Item Entry Relation";
        LSCTenderTypeSetup: Record "LSC Tender Type Setup";
        TenderTypeEntry: Record "BPC Tender Type Entry";
        Customer: Record Customer;
        LSCTransInfocodeEntry: Record "LSC Trans. Infocode Entry";
        POSDataEntry: Record "LSC POS Data Entry";
        FieldRef: FieldRef;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ReturnShptHeader: Record "Return Shipment Header";
        ReturnShptLine: Record "Return Shipment Line";
        TransfHeader: Record "Transfer Header";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        TransferShipmentLine: Record "Transfer Shipment Line";
        TransfLine: Record "Transfer Line";
        ReservationEntry: Record "Reservation Entry";
        Item: Record Item;
        ItemTracking: Record "Item Tracking Code";
        Barcodes: Record "LSC Barcodes";
        ItemUOM: Record "Item Unit of Measure";
        PostedStmt: Record "LSC Posted Statement";
        PostedStmtLine: Record "LSC Posted Statement Line";
        CalcStmtLine: Record "LSC Posted Statement Line";
        TempSalesEntry: Record "LSC Trans. Sales Entry" temporary;
        TempPostedStmtLine: Record "LSC Posted Statement Line" temporary;
        TempPaymentEntry: Record "LSC Trans. Payment Entry" temporary;
        ItemLedgEntry: Record "Item Ledger Entry";
        ItemLedgEntry2: Record "Item Ledger Entry";
        TempLedgEntry: Record "Item Ledger Entry" temporary;
        TempLedgEntry2: Record "Item Ledger Entry" temporary;
        TenderType: Record "LSC Tender Type";
        POSVATCode: Record "LSC POS VAT Code";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemLedEnt: Record "Item Ledger Entry";
        POSCardEntry: Record "LSC POS Card Entry";
        VariantName: Text[60];
        lnWorksheetSeqNo: Integer;
        RoundingAmt: Decimal;
        TransAmt: Decimal;
        Qty: Decimal;
        VATBase7: Decimal;
        VATBase0: Decimal;
        VATAmt: Decimal;
        TransactionNo: Text;
        POS1: Integer;
        POS2: Integer;
        POS3: Integer;
        LocDocumentNo: Text;
        ItemLedgerNo: Text;
        Skip: Boolean;
        VoucherNo: TEXT;
        CheckDocShipmentLine: text;
        ShipmentLine: Integer;
        Bomi: Integer;
        i: Integer;
        DS_No: Integer;
        CountLineJSon: Integer;
        Rounding: Decimal;
        SkipReturn: Boolean;
        VoucherEntriesTmp: Record "BPC.Voucher Entries Tmp";
        CalcTransAmt: Decimal;
    begin
        Clear(JsonUtil);
        VoucherEntriesTmp.DeleteAll();
        case SelectionFunctions of
            'PostTransfersReceipt':
                begin
                    TransferReceiptHeader.Reset();
                    TransferReceiptHeader.SetRange("No.", GetFieldValue(pRecRef, 'No.'));
                    if TransferReceiptHeader.FindSet() then begin
                        // TransferReceiptHeader.Reset();
                        // TransferReceiptHeader.SetRange("Transfer Order No.", TransfHeader."No.");
                        // if TransferReceiptHeader.FindSet() then begin
                        JsonUtil.StartJSon();
                        // Header
                        // JsonUtil.AddToJSon('Transf_No', TransfHeader."No.");
                        // JsonUtil.AddToJSon('Transf_Storefrom', TransfHeader."LSC Store-from");
                        // JsonUtil.AddToJSon('Transf_Transffrom', TransfHeader."Transfer-from Code");
                        // JsonUtil.AddToJSon('Transf_Storeto', TransfHeader."LSC Store-to");
                        // JsonUtil.AddToJSon('Transf_Transfto', TransfHeader."Transfer-to Code");
                        // JsonUtil.AddToJSon('Transf_PostingDate', FORMAT(TransfHeader."Posting Date", 0, '<Year4>-<Month,2>-<Day,2>'));
                        JsonUtil.AddToJSon('Transf_No', TransferReceiptHeader."Transfer Order No.");
                        JsonUtil.AddToJSon('Transf_Storefrom', TransferReceiptHeader."LSC Store-from");
                        JsonUtil.AddToJSon('Transf_Transffrom', TransferReceiptHeader."Transfer-from Code");
                        JsonUtil.AddToJSon('Transf_Storeto', TransferReceiptHeader."LSC Store-to");
                        JsonUtil.AddToJSon('Transf_Transfto', TransferReceiptHeader."Transfer-to Code");
                        JsonUtil.AddToJSon('Transf_PostingDate', FORMAT(TransferReceiptHeader."Posting Date", 0, '<Year4>-<Month,2>-<Day,2>'));

                        // Line
                        TransferReceiptLine.Reset();
                        TransferReceiptLine.SetRange("Document No.", TransferReceiptHeader."No.");
                        TransferReceiptLine.SETFILTER(Quantity, '<>0');
                        if TransferReceiptLine.FindSet() then begin
                            JsonUtil.StartJSonArray('TransfL');
                            repeat
                                JsonUtil.StartJSon();
                                JsonUtil.AddToJSon('TransfL_DocNo', TransferReceiptLine."Document No.");
                                JsonUtil.AddToJSon('TransfL_LineNo', TransferReceiptLine."Line No.");
                                JsonUtil.AddToJSon('TransfL_ItemNo', TransferReceiptLine."Item No.");
                                JsonUtil.AddToJSon('TransfL_Location', '');
                                JsonUtil.AddToJSon('TransfL_Qty', TransferReceiptLine."Quantity (Base)");
                                JsonUtil.AddToJSon('TransfL_UM', TransferReceiptLine."Unit of Measure Code");
                                Item.Get(TransferReceiptLine."Item No.");
                                if NOT ItemTracking.Get(Item."Item Tracking Code") then
                                    ItemTracking.Init();
                                ItemVariantRegistration.Reset();
                                ItemVariantRegistration.SETFILTER("Item No.", '%1', TransferReceiptLine."Item No.");
                                ItemVariantRegistration.SETFILTER(Variant, '%1', TransferReceiptLine."Variant Code");
                                if NOT ItemVariantRegistration.FindSet() then
                                    ItemVariantRegistration.Init();
                                JsonUtil.AddToJSon('TransfL_Variant', ItemVariantRegistration."Variant Dimension 1");
                                // Serial
                                if NOT ItemTracking.Get(Item."Item Tracking Code") then
                                    ItemTracking.Init();

                                ItemEntryRelation.Reset();
                                ItemEntryRelation.SetRange("Source Type", Database::"Transfer Receipt Line");
                                ItemEntryRelation.SetRange("Source Subtype", 0);
                                ItemEntryRelation.SetRange("Source ID", TransferReceiptLine."Document No.");
                                ItemEntryRelation.SetRange("Source Ref. No.", TransferReceiptLine."Line No.");
                                if ItemEntryRelation.FindSet() then begin
                                    JsonUtil.StartJSonArray('Serial');
                                    repeat
                                        ItemLedEnt.Reset();
                                        ItemLedEnt.SetRange("Entry No.", ItemEntryRelation."Item Entry No.");
                                        if ItemLedEnt.FindSet() then begin
                                            JsonUtil.StartJSon();
                                            JsonUtil.AddToJSon('Serial_ItemNo', ItemLedEnt."Item No.");
                                            JsonUtil.AddToJSon('Serial_No', ItemLedEnt."Serial No.");
                                            JsonUtil.AddToJSon('Serial_Qty', ABS(ItemLedEnt."Quantity"));
                                            JsonUtil.EndJSon();
                                        end;
                                    until ItemEntryRelation.Next() = 0;
                                    JsonUtil.EndJSonArray;
                                end else begin
                                    JsonUtil.StartJSonArray('Serial');
                                    JsonUtil.StartJSon();
                                    JsonUtil.AddToJSon('Serial_ItemNo', '');
                                    JsonUtil.AddToJSon('Serial_No', '');
                                    JsonUtil.AddToJSon('Serial_Qty', '');
                                    JsonUtil.EndJSon();
                                    JsonUtil.EndJSonArray;
                                end;
                                // if ItemTracking."SN Specific Tracking" then begin
                                //     ItemLedEnt.Reset();
                                //     ItemLedEnt.SetRange("Document No.", TransferReceiptLine."Document No.");
                                //     ItemLedEnt.SetRange("Document Line No.", TransferReceiptLine."Line No.");
                                //     ItemLedEnt.SetRange("Entry Type", ItemLedEnt."Entry Type"::Transfer);
                                //     if ItemLedEnt.FindSet() then begin
                                //         if ItemLedEnt."Serial No." <> '' then begin
                                //             JsonUtil.StartJSonArray('Serial');
                                //             JsonUtil.StartJSon();
                                //             JsonUtil.AddToJSon('Serial_ItemNo', ItemLedEnt."Item No.");
                                //             JsonUtil.AddToJSon('Serial_No', ItemLedEnt."Serial No.");
                                //             JsonUtil.AddToJSon('Serial_Qty', ABS(ItemLedEnt."Quantity"));
                                //             JsonUtil.EndJSon();
                                //             JsonUtil.EndJSonArray;
                                //         end else begin
                                //             JsonUtil.StartJSonArray('Serial');
                                //             JsonUtil.StartJSon();
                                //             JsonUtil.AddToJSon('Serial_ItemNo', '');
                                //             JsonUtil.AddToJSon('Serial_No', '');
                                //             JsonUtil.AddToJSon('Serial_Qty', '');
                                //             JsonUtil.EndJSon();
                                //             JsonUtil.EndJSonArray;
                                //         end;
                                //         if ItemLedEnt."Lot No." <> '' then begin
                                //             JsonUtil.StartJSonArray('Batch');
                                //             JsonUtil.StartJSon();
                                //             JsonUtil.AddToJSon('Batch_ItemNo', ItemLedEnt."Item No.");
                                //             JsonUtil.AddToJSon('Batch_No', ItemLedEnt."Lot No.");
                                //             JsonUtil.AddToJSon('Batch_Qty', ABS(ItemLedEnt."Quantity"));
                                //             JsonUtil.EndJSonArray;
                                //         end else begin
                                //             JsonUtil.StartJSonArray('Batch');
                                //             JsonUtil.StartJSon();
                                //             JsonUtil.AddToJSon('Batch_ItemNo', '');
                                //             JsonUtil.AddToJSon('Batch_No', '');
                                //             JsonUtil.AddToJSon('Batch_Qty', '');
                                //             JsonUtil.EndJSon();
                                //             JsonUtil.EndJSonArray;
                                //         end;
                                //     end;
                                // end;
                                JsonUtil.EndJSon();
                            until TransferReceiptLine.Next() = 0;
                            JsonUtil.EndJSonArray;
                        end;
                        JsonUtil.EndJSon();
                    end;
                end;
            'PostTransfersShipment':
                begin
                    TransfHeader.Reset();
                    TransfHeader.SetRange("No.", GetFieldValue(pRecRef, 'No.'));
                    if TransfHeader.FindSet() then begin
                        JsonUtil.StartJSon();
                        // Header
                        JsonUtil.AddToJSon('Transf_No', TransfHeader."No.");
                        JsonUtil.AddToJSon('Transf_Storefrom', TransfHeader."LSC Store-from");
                        JsonUtil.AddToJSon('Transf_Transffrom', TransfHeader."Transfer-from Code");
                        JsonUtil.AddToJSon('Transf_Storeto', TransfHeader."LSC Store-to");
                        JsonUtil.AddToJSon('Transf_Transfto', TransfHeader."Transfer-to Code");
                        JsonUtil.AddToJSon('Transf_PostingDate', FORMAT(TransfHeader."Posting Date", 0, '<Year4>-<Month,2>-<Day,2>'));
                        // Line
                        TransferShipmentHeader.Reset();
                        TransferShipmentHeader.SetRange("Transfer Order No.", TransfHeader."No.");
                        if TransferShipmentHeader.FindSet() then begin
                            TransferShipmentLine.Reset();
                            TransferShipmentLine.SetRange("Document No.", TransferShipmentHeader."No.");
                            TransferShipmentLine.SETFILTER(Quantity, '<>0');
                            if TransferShipmentLine.FindSet() then begin
                                JsonUtil.StartJSonArray('TransfL');
                                repeat
                                    JsonUtil.StartJSon();
                                    JsonUtil.AddToJSon('TransfL_DocNo', TransferShipmentLine."Document No.");
                                    JsonUtil.AddToJSon('TransfL_LineNo', TransferShipmentLine."Line No.");
                                    JsonUtil.AddToJSon('TransfL_ItemNo', TransferShipmentLine."Item No.");
                                    JsonUtil.AddToJSon('TransfL_Location', '');
                                    JsonUtil.AddToJSon('TransfL_Qty', TransferShipmentLine."Quantity (Base)");
                                    JsonUtil.AddToJSon('TransfL_UM', TransferShipmentLine."Unit of Measure Code");

                                    Item.Get(TransferShipmentLine."Item No.");
                                    if NOT ItemTracking.Get(Item."Item Tracking Code") then
                                        ItemTracking.Init();

                                    ItemVariantRegistration.Reset();
                                    ItemVariantRegistration.SETFILTER("Item No.", '%1', TransferShipmentLine."Item No.");
                                    ItemVariantRegistration.SETFILTER(Variant, '%1', TransferShipmentLine."Variant Code");
                                    if NOT ItemVariantRegistration.FindSet() then
                                        ItemVariantRegistration.Init();
                                    JsonUtil.AddToJSon('TransfL_Variant', ItemVariantRegistration."Variant Dimension 1");
                                    // Serial
                                    if NOT ItemTracking.Get(Item."Item Tracking Code") then
                                        ItemTracking.Init();

                                    ItemEntryRelation.Reset();
                                    ItemEntryRelation.SetRange("Source Type", Database::"Transfer Shipment Line");
                                    ItemEntryRelation.SetRange("Source Subtype", 0);
                                    ItemEntryRelation.SetRange("Source ID", TransferShipmentLine."Document No.");
                                    ItemEntryRelation.SetRange("Source Ref. No.", TransferShipmentLine."Line No.");
                                    if ItemEntryRelation.FindSet() then begin
                                        JsonUtil.StartJSonArray('Serial');
                                        repeat
                                            ItemLedEnt.Reset();
                                            ItemLedEnt.SetRange("Entry No.", ItemEntryRelation."Item Entry No.");
                                            if ItemLedEnt.FindSet() then begin
                                                JsonUtil.StartJSon();
                                                JsonUtil.AddToJSon('Serial_ItemNo', ItemLedEnt."Item No.");
                                                JsonUtil.AddToJSon('Serial_No', ItemLedEnt."Serial No.");
                                                JsonUtil.AddToJSon('Serial_Qty', ABS(ItemLedEnt."Quantity"));
                                                JsonUtil.EndJSon();
                                            end;
                                        until ItemEntryRelation.Next() = 0;
                                        JsonUtil.EndJSonArray;
                                    end else begin
                                        JsonUtil.StartJSonArray('Serial');
                                        JsonUtil.StartJSon();
                                        JsonUtil.AddToJSon('Serial_ItemNo', '');
                                        JsonUtil.AddToJSon('Serial_No', '');
                                        JsonUtil.AddToJSon('Serial_Qty', '');
                                        JsonUtil.EndJSon();
                                        JsonUtil.EndJSonArray;
                                    end;
                                    // if ItemTracking."SN Specific Tracking" then begin
                                    //     ItemLedEnt.Reset();
                                    //     ItemLedEnt.SetRange("Document No.", TransferShipmentLine."Document No.");
                                    //     ItemLedEnt.SetRange("Document Line No.", TransferShipmentLine."Line No.");
                                    //     ItemLedEnt.SetRange("Entry Type", ItemLedEnt."Entry Type"::Transfer);
                                    //     if ItemLedEnt.FindSet() then begin
                                    //         if ItemLedEnt."Serial No." <> '' then begin
                                    //             JsonUtil.StartJSonArray('Serial');
                                    //             JsonUtil.StartJSon();
                                    //             JsonUtil.AddToJSon('Serial_ItemNo', ItemLedEnt."Item No.");
                                    //             JsonUtil.AddToJSon('Serial_No', ItemLedEnt."Serial No.");
                                    //             JsonUtil.AddToJSon('Serial_Qty', ABS(ItemLedEnt."Quantity"));
                                    //             JsonUtil.EndJSon();
                                    //             JsonUtil.EndJSonArray;
                                    //         end else begin
                                    //             JsonUtil.StartJSonArray('Serial');
                                    //             JsonUtil.StartJSon();
                                    //             JsonUtil.AddToJSon('Serial_ItemNo', '');
                                    //             JsonUtil.AddToJSon('Serial_No', '');
                                    //             JsonUtil.AddToJSon('Serial_Qty', '');
                                    //             JsonUtil.EndJSon();
                                    //             JsonUtil.EndJSonArray;
                                    //         end;
                                    //         if ItemLedEnt."Lot No." <> '' then begin
                                    //             JsonUtil.StartJSonArray('Batch');
                                    //             JsonUtil.StartJSon();
                                    //             JsonUtil.AddToJSon('Batch_ItemNo', ItemLedEnt."Item No.");
                                    //             JsonUtil.AddToJSon('Batch_No', ItemLedEnt."Lot No.");
                                    //             JsonUtil.AddToJSon('Batch_Qty', ABS(ItemLedEnt."Quantity"));
                                    //             JsonUtil.EndJSonArray;
                                    //         end else begin
                                    //             JsonUtil.StartJSonArray('Batch');
                                    //             JsonUtil.StartJSon();
                                    //             JsonUtil.AddToJSon('Batch_ItemNo', '');
                                    //             JsonUtil.AddToJSon('Batch_No', '');
                                    //             JsonUtil.AddToJSon('Batch_Qty', '');
                                    //             JsonUtil.EndJSon();
                                    //             JsonUtil.EndJSonArray;
                                    //         end;
                                    //     end;
                                    // end;
                                    JsonUtil.EndJSon();
                                until TransferShipmentLine.Next() = 0;
                                JsonUtil.EndJSonArray;
                            end;
                            JsonUtil.EndJSon();
                        end;
                    end;
                end;
            'PostPurchaseShipment':
                begin
                    PurchHeader.Reset();
                    PurchHeader.SETFILTER("Document Type", GetFieldValue(pRecRef, 'Document Type'));
                    PurchHeader.SETFILTER("No.", GetFieldValue(pRecRef, 'No.'));
                    if PurchHeader.FindSet() then begin
                        JsonUtil.StartJSon('PurchH');
                        // Header
                        JsonUtil.AddToJSon('PurchH_PONo', PurchHeader."No.");
                        JsonUtil.AddToJSon('PurchH_VendShipNo', PurchHeader."Vendor Shipment No.");
                        JsonUtil.AddToJSon('PurchH_BuyfromVendNo', PurchHeader."Buy-from Vendor No.");
                        JsonUtil.AddToJSon('PurchH_VendInvNo', PurchHeader."Vendor Invoice No.");
                        JsonUtil.AddToJSon('PurchH_PostingDate', FORMAT(PurchHeader."Posting Date", 0, '<Year4>-<Month,2>-<Day,2>'));
                        JsonUtil.AddToJSon('PurchH_DocumentDate', FORMAT(PurchHeader."Document Date", 0, '<Year4>-<Month,2>-<Day,2>'));
                        // Line
                        PurchLine.Reset();
                        PurchLine.SetRange("Document No.", PurchHeader."No.");
                        PurchLine.SETFILTER("Qty. to Receive", '<>%1', 0);
                        if PurchLine.FindSet() then begin
                            JsonUtil.StartJSonArray('PurchL');
                            repeat
                                if NOT Item.Get(PurchLine."No.") then
                                    Item.Init();
                                if NOT ItemTracking.Get(Item."Item Tracking Code") then
                                    ItemTracking.Init();
                                JsonUtil.StartJSon();
                                JsonUtil.AddToJSon('PurchL_DocNo', PurchLine."Document No.");
                                JsonUtil.AddToJSon('PurchL_OrderNo', PurchLine."Order No.");
                                JsonUtil.AddToJSon('PurchL_LineNo', PurchLine."Line No.");
                                JsonUtil.AddToJSon('PurchL_ItemNo', PurchLine."No.");
                                JsonUtil.AddToJSon('PurchL_Location', PurchLine."Location Code");
                                JsonUtil.AddToJSon('PurchL_Qty', PurchLine."Quantity (Base)");
                                JsonUtil.AddToJSon('PurchL_QtyToReceive', PurchLine."Qty. to Receive (Base)");
                                JsonUtil.AddToJSon('PurchL_Variant', '');
                                JsonUtil.AddToJSon('PurchL_VariantName', '');
                                // Serial ++
                                if ItemTracking."SN Specific Tracking" then begin
                                    ReservationEntry.Reset();
                                    ReservationEntry.SetRange("Source Type", DATABASE::"Purchase Line");
                                    ReservationEntry.SetRange("Source ID", PurchLine."Document No.");
                                    ReservationEntry.SetRange("Item No.", PurchLine."No.");
                                    ReservationEntry.SetRange("Location Code", PurchLine."Location Code");
                                    ReservationEntry.SetRange("Source Type", DATABASE::"Purchase Line");
                                    ReservationEntry.SetRange("Source Ref. No.", PurchLine."Line No.");
                                    ReservationEntry.SETFILTER("Serial No.", '<>%1', '');
                                    if ReservationEntry.FINDFIRST then begin
                                        JsonUtil.StartJSonArray('Serial');
                                        repeat
                                            JsonUtil.StartJSon();
                                            JsonUtil.AddToJSon('Serial_ItemNo', ReservationEntry."Item No.");
                                            JsonUtil.AddToJSon('Serial_No', ReservationEntry."Serial No.");
                                            JsonUtil.AddToJSon('Serial_Qty', ReservationEntry.Quantity);
                                            JsonUtil.EndJSon();
                                        until ReservationEntry.Next() = 0;
                                        JsonUtil.EndJSonArray;
                                    end;
                                end;
                                // Serial --
                                // Batch/Lot ++
                                if (ItemTracking."Lot Specific Tracking") AND (ItemTracking."BPC.Lot Default to ERP" = '') then begin
                                    ReservationEntry.Reset();
                                    ReservationEntry.SetRange("Source Type", DATABASE::"Purchase Line");
                                    ReservationEntry.SetRange("Source ID", PurchLine."Document No.");
                                    ReservationEntry.SetRange("Item No.", PurchLine."No.");
                                    ReservationEntry.SetRange("Location Code", PurchLine."Location Code");
                                    ReservationEntry.SetRange("Source Type", DATABASE::"Purchase Line");
                                    ReservationEntry.SetRange("Source Ref. No.", PurchLine."Line No.");
                                    ReservationEntry.SETFILTER("Lot No.", '<>%1', '');
                                    if ReservationEntry.FINDFIRST then begin
                                        JsonUtil.StartJSonArray('Batch');
                                        repeat
                                            JsonUtil.StartJSon();
                                            JsonUtil.AddToJSon('Batch_ItemNo', ReservationEntry."Item No.");
                                            JsonUtil.AddToJSon('Batch_No', ReservationEntry."Lot No.");
                                            JsonUtil.AddToJSon('Batch_Qty', ReservationEntry.Quantity);
                                            JsonUtil.AddToJSon('Batch_ExpireDate', FORMAT(ReservationEntry."Expiration Date", 0, '<Year4>-<Month,2>-<Day,2>'));
                                            JsonUtil.EndJSon();
                                        until ReservationEntry.Next() = 0;
                                        JsonUtil.EndJSonArray;
                                    end;
                                end else
                                    if ItemTracking."BPC.Lot Default to ERP" <> '' then begin
                                        JsonUtil.StartJSonArray('Batch');
                                        JsonUtil.StartJSon();
                                        JsonUtil.AddToJSon('Batch_ItemNo', PurchLine."No.");
                                        JsonUtil.AddToJSon('Batch_No', ItemTracking."BPC.Lot Default to ERP");
                                        JsonUtil.AddToJSon('Batch_Qty', PurchLine."Qty. to Receive (Base)");
                                        JsonUtil.EndJSon();
                                        JsonUtil.EndJSonArray;
                                    end;
                                // Batch/Lot ++
                                JsonUtil.EndJSon();
                            until PurchLine.Next() = 0;
                            JsonUtil.EndJSonArray;
                        end;
                        JsonUtil.EndJSon();
                    end;
                end;
            'PostPurchaseReceive':
                begin
                    PurchHeader.Reset();
                    PurchHeader.SETFILTER("Document Type", GetFieldValue(pRecRef, 'Document Type'));
                    PurchHeader.SETFILTER("No.", GetFieldValue(pRecRef, 'No.'));
                    if PurchHeader.FindSet() then begin
                        JsonUtil.StartJSon('PurchH');
                        // Header
                        JsonUtil.AddToJSon('PurchH_PONo', PurchHeader."No.");
                        JsonUtil.AddToJSon('PurchH_VendShipNo', PurchHeader."Vendor Shipment No.");
                        JsonUtil.AddToJSon('PurchH_BuyfromVendNo', PurchHeader."Buy-from Vendor No.");
                        JsonUtil.AddToJSon('PurchH_VendInvNo', PurchHeader."Vendor Invoice No.");
                        JsonUtil.AddToJSon('PurchH_PostingDate', Format(PurchHeader."Posting Date", 0, '<Year4>-<Month,2>-<Day,2>'));
                        JsonUtil.AddToJSon('PurchH_DocumentDate', Format(PurchHeader."Document Date", 0, '<Year4>-<Month,2>-<Day,2>'));
                        // Line
                        PurchLine.Reset();
                        PurchLine.SetRange("Document No.", PurchHeader."No.");
                        PurchLine.SETFILTER("Qty. to Receive", '<>%1', 0);
                        if PurchLine.FindSet() then begin
                            JsonUtil.StartJSonArray('PurchL');
                            repeat
                                if NOT Item.Get(PurchLine."No.") then
                                    Item.Init();
                                if NOT ItemTracking.Get(Item."Item Tracking Code") then
                                    ItemTracking.Init();
                                JsonUtil.StartJSon();
                                JsonUtil.AddToJSon('PurchL_DocNo', PurchLine."Document No.");
                                JsonUtil.AddToJSon('PurchL_OrderNo', PurchLine."Order No.");
                                JsonUtil.AddToJSon('PurchL_LineNo', PurchLine."Line No.");
                                JsonUtil.AddToJSon('PurchL_ItemNo', PurchLine."No.");
                                JsonUtil.AddToJSon('PurchL_Location', PurchLine."Location Code");
                                JsonUtil.AddToJSon('PurchL_Qty', PurchLine."Quantity (Base)");
                                JsonUtil.AddToJSon('PurchL_QtyToReceive', PurchLine."Qty. to Receive (Base)");
                                JsonUtil.AddToJSon('PurchL_Variant', '');
                                JsonUtil.AddToJSon('PurchL_VariantName', '');
                                // Serial ++
                                if ItemTracking."SN Specific Tracking" then begin
                                    ReservationEntry.Reset();
                                    ReservationEntry.SetRange("Source Type", DATABASE::"Purchase Line");
                                    ReservationEntry.SetRange("Source ID", PurchLine."Document No.");
                                    ReservationEntry.SetRange("Item No.", PurchLine."No.");
                                    ReservationEntry.SetRange("Location Code", PurchLine."Location Code");
                                    ReservationEntry.SetRange("Source Type", DATABASE::"Purchase Line");
                                    ReservationEntry.SetRange("Source Ref. No.", PurchLine."Line No.");
                                    ReservationEntry.SETFILTER("Serial No.", '<>%1', '');
                                    if ReservationEntry.FINDFIRST then begin
                                        JsonUtil.StartJSonArray('Serial');
                                        repeat
                                            JsonUtil.StartJSon();
                                            JsonUtil.AddToJSon('Serial_ItemNo', ReservationEntry."Item No.");
                                            JsonUtil.AddToJSon('Serial_No', ReservationEntry."Serial No.");
                                            JsonUtil.AddToJSon('Serial_Qty', ReservationEntry.Quantity);
                                            JsonUtil.EndJSon();
                                        until ReservationEntry.Next() = 0;
                                        JsonUtil.EndJSonArray;
                                    end;
                                end;
                                // Serial --
                                // Batch/Lot ++
                                if (ItemTracking."Lot Specific Tracking") AND (ItemTracking."BPC.Lot Default to ERP" = '') then begin
                                    ReservationEntry.Reset();
                                    ReservationEntry.SetRange("Source Type", DATABASE::"Purchase Line");
                                    ReservationEntry.SetRange("Source ID", PurchLine."Document No.");
                                    ReservationEntry.SetRange("Item No.", PurchLine."No.");
                                    ReservationEntry.SetRange("Location Code", PurchLine."Location Code");
                                    ReservationEntry.SetRange("Source Type", DATABASE::"Purchase Line");
                                    ReservationEntry.SetRange("Source Ref. No.", PurchLine."Line No.");
                                    ReservationEntry.SETFILTER("Lot No.", '<>%1', '');
                                    if ReservationEntry.FINDFIRST then begin
                                        JsonUtil.StartJSonArray('Batch');
                                        repeat
                                            JsonUtil.StartJSon();
                                            JsonUtil.AddToJSon('Batch_ItemNo', ReservationEntry."Item No.");
                                            JsonUtil.AddToJSon('Batch_No', ReservationEntry."Lot No.");
                                            JsonUtil.AddToJSon('Batch_Qty', ReservationEntry.Quantity);
                                            JsonUtil.AddToJSon('Batch_ExpireDate', FORMAT(ReservationEntry."Expiration Date", 0, '<Year4>-<Month,2>-<Day,2>'));
                                            JsonUtil.EndJSon();
                                        until ReservationEntry.Next() = 0;
                                        JsonUtil.EndJSonArray;
                                    end;
                                end else
                                    if ItemTracking."BPC.Lot Default to ERP" <> '' then begin
                                        JsonUtil.StartJSonArray('Batch');
                                        JsonUtil.StartJSon();
                                        JsonUtil.AddToJSon('Batch_ItemNo', PurchLine."No.");
                                        JsonUtil.AddToJSon('Batch_No', ItemTracking."BPC.Lot Default to ERP");
                                        JsonUtil.AddToJSon('Batch_Qty', PurchLine."Qty. to Receive (Base)");
                                        JsonUtil.EndJSon();
                                        JsonUtil.EndJSonArray;
                                    end;
                                // Batch/Lot ++
                                JsonUtil.EndJSon();
                            until PurchLine.Next() = 0;
                            JsonUtil.EndJSonArray;
                        end;
                        JsonUtil.EndJSon();
                    end;
                end;
            'SendPurchaseReceive':
                begin
                    PurchRcptHeader.Reset();
                    PurchRcptHeader.SETFILTER("No.", GetFieldValue(pRecRef, 'No.'));
                    if PurchRcptHeader.FindSet() then begin
                        PurchHeader.Get(PurchHeader."Document Type"::Order, PurchRcptHeader."Order No.");
                        JsonUtil.StartJSon();
                        // Header
                        JsonUtil.AddToJSon('PurchH_PONo', PurchRcptHeader."Order No.");
                        JsonUtil.AddToJSon('PurchH_GRNNo', PurchRcptHeader."No.");
                        JsonUtil.AddToJSon('PurchH_VendShipNo', PurchRcptHeader."Vendor Shipment No.");
                        JsonUtil.AddToJSon('PurchH_BuyfromVendNo', PurchRcptHeader."Buy-from Vendor No.");
                        JsonUtil.AddToJSon('PurchH_VendInvNo', PurchHeader."Vendor Invoice No.");
                        JsonUtil.AddToJSon('PurchH_PostingDate', Format(PurchRcptHeader."Posting Date", 0, '<Year4>-<Month,2>-<Day,2>'));
                        JsonUtil.AddToJSon('PurchH_DocumentDate', Format(PurchRcptHeader."Document Date", 0, '<Year4>-<Month,2>-<Day,2>'));
                        // Line
                        PurchRcptLine.Reset();
                        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
                        PurchRcptLine.SETFILTER(Quantity, '<>%1', 0);
                        if PurchRcptLine.FindSet() then begin
                            JsonUtil.StartJSonArray('PurchL');
                            repeat
                                if NOT Item.Get(PurchRcptLine."No.") then
                                    Item.Init();
                                if NOT ItemTracking.Get(Item."Item Tracking Code") then
                                    ItemTracking.Init();
                                JsonUtil.StartJSon();
                                JsonUtil.AddToJSon('PurchL_DocNo', PurchRcptLine."Document No.");
                                JsonUtil.AddToJSon('PurchL_OrderNo', PurchRcptLine."Order No.");
                                JsonUtil.AddToJSon('PurchL_LineNo', PurchRcptLine."Line No." / 10000);
                                JsonUtil.AddToJSon('PurchL_ItemNo', PurchRcptLine."No.");
                                JsonUtil.AddToJSon('PurchL_Location', PurchRcptLine."Location Code");
                                JsonUtil.AddToJSon('PurchL_Qty', PurchRcptLine."Quantity (Base)");
                                JsonUtil.AddToJSon('PurchL_QtyToReceive', PurchRcptLine."Quantity (Base)");
                                JsonUtil.AddToJSon('PurchL_Variant', '');
                                JsonUtil.AddToJSon('PurchL_VariantName', '');
                                // Serial ++
                                if ItemTracking."SN Specific Tracking" then begin
                                    ItemLedgEntry.Reset();
                                    ItemLedgEntry.SetRange("Document Type", ItemLedgEntry."Document Type"::"Purchase Receipt");
                                    ItemLedgEntry.SetRange("Document No.", PurchRcptLine."Document No.");
                                    ItemLedgEntry.SetRange("Document Line No.", PurchRcptLine."Line No.");
                                    ItemLedgEntry.SETFILTER("Serial No.", '<>%1', '');
                                    if ItemLedgEntry.FINDFIRST then begin
                                        JsonUtil.StartJSonArray('Serial');
                                        repeat
                                            JsonUtil.StartJSon();
                                            JsonUtil.AddToJSon('Serial_ItemNo', ItemLedgEntry."Item No.");
                                            JsonUtil.AddToJSon('Serial_No', ItemLedgEntry."Serial No.");
                                            JsonUtil.AddToJSon('Serial_Qty', ItemLedgEntry.Quantity);
                                            JsonUtil.EndJSon();
                                        until ItemLedgEntry.Next() = 0;
                                        JsonUtil.EndJSonArray;
                                    end;
                                end;
                                // Serial --
                                // Batch/Lot ++
                                if (ItemTracking."Lot Specific Tracking") AND (ItemTracking."BPC.Lot Default to ERP" = '') then begin
                                    ItemLedgEntry.Reset();
                                    ItemLedgEntry.SetRange("Document Type", ItemLedgEntry."Document Type"::"Purchase Receipt");
                                    ItemLedgEntry.SetRange("Document No.", PurchRcptLine."Document No.");
                                    ItemLedgEntry.SetRange("Document Line No.", PurchRcptLine."Line No.");
                                    ItemLedgEntry.SETFILTER("Lot No.", '<>%1', '');
                                    if ItemLedgEntry.FINDFIRST then begin
                                        JsonUtil.StartJSonArray('Batch');
                                        repeat
                                            JsonUtil.StartJSon();
                                            JsonUtil.AddToJSon('Batch_ItemNo', ItemLedgEntry."Item No.");
                                            JsonUtil.AddToJSon('Batch_No', ItemLedgEntry."Lot No.");
                                            JsonUtil.AddToJSon('Batch_Qty', ItemLedgEntry.Quantity);
                                            JsonUtil.AddToJSon('Batch_ExpireDate', FORMAT(ItemLedgEntry."Expiration Date", 0, '<Year4>-<Month,2>-<Day,2>'));
                                            JsonUtil.EndJSon();
                                        until ItemLedgEntry.Next() = 0;
                                        JsonUtil.EndJSonArray;
                                    end;
                                end else
                                    if ItemTracking."BPC.Lot Default to ERP" <> '' then begin
                                        JsonUtil.StartJSonArray('Batch');
                                        JsonUtil.StartJSon();
                                        JsonUtil.AddToJSon('Batch_ItemNo', PurchRcptLine."No.");
                                        JsonUtil.AddToJSon('Batch_No', ItemTracking."BPC.Lot Default to ERP");
                                        JsonUtil.AddToJSon('Batch_Qty', PurchRcptLine."Quantity (Base)");
                                        JsonUtil.EndJSon();
                                        JsonUtil.EndJSonArray;
                                    end;
                                // Batch/Lot ++
                                JsonUtil.EndJSon();
                            until PurchRcptLine.Next() = 0;
                            JsonUtil.EndJSonArray;
                        end;
                        JsonUtil.EndJSon();
                    end;
                end;
            'SendChkInvenLookupInStock':
                begin
                    pRecRef.Reset();
                    if pRecRef.FindSet() then begin
                        JsonUtil.StartJSon();
                        JsonUtil.StartJSonArray('ItemList');
                        JsonUtil.StartJSon();
                        JsonUtil.AddToJSon('Invent_Item', GetFieldValue(pRecRef, 'Item No.'));
                        JsonUtil.StartJSonArray('Store');
                        repeat
                            JsonUtil.StartJSon();
                            JsonUtil.AddToJSon('Invent_Warehouses', GetFieldValue(pRecRef, 'Location'));
                            JsonUtil.EndJSon();
                        until pRecRef.Next() = 0;
                        JsonUtil.EndJSonArray;
                        JsonUtil.EndJSon();
                        JsonUtil.EndJSonArray;
                        JsonUtil.EndJSon();
                    end;
                end;
            'PostInventCountingJournal':
                begin
                    if EVALUATE(lnWorksheetSeqNo, GetFieldValue(pRecRef, 'WorksheetSeqNo')) then;
                    StoreInventoryWorksheet.Reset();
                    StoreInventoryWorksheet.SetRange(WorksheetSeqNo, lnWorksheetSeqNo);
                    if StoreInventoryWorksheet.FindSet() then begin
                        JsonUtil.StartJSon();
                        // Header
                        JsonUtil.AddToJSon('StoreIvH_WShSeqNo', StoreInventoryWorksheet.WorksheetSeqNo);
                        JsonUtil.AddToJSon('StoreIvH_StoreNo', StoreInventoryWorksheet."Store No.");
                        JsonUtil.AddToJSon('StoreIvH_LocationCode', StoreInventoryWorksheet."Location Code");
                        // Line
                        StoreInventoryLine.Reset();
                        StoreInventoryLine.SetRange(WorksheetSeqNo, StoreInventoryWorksheet.WorksheetSeqNo);
                        if StoreInventoryLine.FindSet() then begin
                            JsonUtil.StartJSonArray('StoreIvL');
                            repeat
                                StoreInventoryLine.TESTFIELD("Posting Date");
                                StoreInventoryLine.TESTFIELD("Item No.");
                                //StoreInventoryLine.TESTFIELD("Qty. (Phys. Inventory)");
                                if NOT Item.Get(StoreInventoryLine."Item No.") then
                                    Item.Init();
                                if NOT ItemTracking.Get(Item."Item Tracking Code") then
                                    ItemTracking.Init();

                                JsonUtil.StartJSon();
                                JsonUtil.AddToJSon('StoreIvL_LineNo', StoreInventoryLine."Line No.");
                                JsonUtil.AddToJSon('StoreIvL_PostingDate', Format(StoreInventoryLine."Posting Date", 0, '<Year4>-<Month,2>-<Day,2>'));
                                JsonUtil.AddToJSon('StoreIvL_ItemNo', StoreInventoryLine."Item No.");
                                ItemVariantRegistration.Reset();
                                ItemVariantRegistration.SETFILTER("Item No.", '%1', StoreInventoryLine."Item No.");
                                ItemVariantRegistration.SETFILTER(Variant, '%1', StoreInventoryLine."Variant Code");
                                if NOT ItemVariantRegistration.FindSet() then
                                    ItemVariantRegistration.Init();
                                JsonUtil.AddToJSon('StoreIvL_Variant', ItemVariantRegistration."Variant Dimension 1");
                                JsonUtil.AddToJSon('StoreIvL_SerialNo', StoreInventoryLine."Serial No.");
                                if ItemTracking."BPC.Lot Default to ERP" <> '' then
                                    JsonUtil.AddToJSon('StoreIvL_BatchNo', ItemTracking."BPC.Lot Default to ERP");
                                JsonUtil.AddToJSon('StoreIvL_Physical', StoreInventoryLine."Qty. (Phys. Inventory)");
                                JsonUtil.AddToJSon('StoreIvL_Counting', StoreInventoryLine."Qty. (Calculated)");
                                JsonUtil.AddToJSon('StoreIvL_Diff', (StoreInventoryLine."Quantity (Base)" - StoreInventoryLine."Qty. (Calculated)"));
                                JsonUtil.EndJSon();
                            until StoreInventoryLine.Next() = 0;
                            JsonUtil.EndJSonArray;
                        end else
                            StoreInventoryLine.TESTFIELD("Item No.");
                        JsonUtil.EndJSon();
                    end;
                end;
            'PostInventAdjustJournal':
                begin
                    if EVALUATE(lnWorksheetSeqNo, GetFieldValue(pRecRef, 'WorksheetSeqNo')) then;
                    StoreInventoryWorksheet.Reset();
                    StoreInventoryWorksheet.SetRange(WorksheetSeqNo, lnWorksheetSeqNo);
                    if StoreInventoryWorksheet.ISEMPTY then
                        ERROR('Noting to Post');

                    StoreInventoryWorksheet.Reset();
                    StoreInventoryWorksheet.SetRange(WorksheetSeqNo, lnWorksheetSeqNo);
                    if StoreInventoryWorksheet.FindSet() then begin
                        JsonUtil.StartJSon();
                        // Header
                        JsonUtil.AddToJSon('StoreIvH_WShSeqNo', StoreInventoryWorksheet.WorksheetSeqNo);
                        JsonUtil.AddToJSon('StoreIvH_StoreNo', StoreInventoryWorksheet."Store No.");
                        JsonUtil.AddToJSon('StoreIvH_LocationCode', StoreInventoryWorksheet."Location Code");
                        // Line
                        StoreInventoryLine.Reset();
                        StoreInventoryLine.SetFilter(WorksheetSeqNo, '%1', StoreInventoryWorksheet.WorksheetSeqNo);
                        if StoreInventoryLine.FindSet() then begin
                            JsonUtil.StartJSonArray('StoreIvL');
                            repeat
                                StoreInventoryLine.TESTFIELD("Posting Date");
                                StoreInventoryLine.TESTFIELD("Item No.");
                                StoreInventoryLine.TESTFIELD("Quantity (Base)");

                                JsonUtil.StartJSon();
                                JsonUtil.AddToJSon('StoreIvL_LineNo', StoreInventoryLine."Line No.");
                                JsonUtil.AddToJSon('StoreIvL_PostingDate', Format(StoreInventoryLine."Posting Date", 0, '<Year4>-<Month,2>-<Day,2>'));
                                JsonUtil.AddToJSon('StoreIvL_ItemNo', StoreInventoryLine."Item No.");
                                ItemVariantRegistration.Reset();
                                ItemVariantRegistration.SETFILTER("Item No.", '%1', StoreInventoryLine."Item No.");
                                ItemVariantRegistration.SETFILTER(Variant, '%1', StoreInventoryLine."Variant Code");
                                if NOT ItemVariantRegistration.FindSet() then
                                    ItemVariantRegistration.Init();
                                JsonUtil.AddToJSon('StoreIvL_Variant', ItemVariantRegistration."Variant Dimension 1");
                                Item.Get(StoreInventoryLine."Item No.");
                                if NOT ItemTracking.Get(Item."Item Tracking Code") then
                                    ItemTracking.Init();
                                if ItemTracking."Lot Transfer Tracking" then begin
                                    if ItemTracking."BPC.Lot Default to ERP" <> '' then
                                        JsonUtil.AddToJSon('StoreIvL_BatchNo', ItemTracking."BPC.Lot Default to ERP");
                                    //ELSE
                                    //JsonUtil.AddToJSon('StoreIvL_BatchNo',StoreInventoryLine."Lot No.");
                                end;
                                if ItemTracking."SN Transfer Tracking" then
                                    JsonUtil.AddToJSon('StoreIvL_SerialNo', StoreInventoryLine."Serial No.");
                                JsonUtil.AddToJSon('StoreIvL_Physical', 0);
                                JsonUtil.AddToJSon('StoreIvL_Counting', 0);
                                if StoreInventoryWorksheet.Type = StoreInventoryWorksheet.Type::"Positive Adjmt." then
                                    JsonUtil.AddToJSon('StoreIvL_Diff', StoreInventoryLine."Quantity (Base)");
                                if StoreInventoryWorksheet.Type = StoreInventoryWorksheet.Type::"Positive Adjmt." then
                                    JsonUtil.AddToJSon('StoreIvL_Diff', -StoreInventoryLine."Quantity (Base)");
                                JsonUtil.EndJSon();
                            until StoreInventoryLine.Next() = 0;
                            JsonUtil.EndJSonArray;
                        end else
                            StoreInventoryLine.TESTFIELD("Item No.");
                        JsonUtil.EndJSon();
                    end;
                end;
            'createProduct':
                begin
                    Item.Get(GetFieldValue(pRecRef, 'No.'));
                    Barcodes.Reset();
                    Barcodes.SetRange("Item No.", Item."No.");
                    Barcodes.SetRange("Show for Item", TRUE);
                    if NOT Barcodes.FindSet() then
                        Barcodes.Init();
                    JsonUtil.StartJSon();
                    JsonUtil.AddToJSon('ItemId', Item."No.");
                    case Item.Type of
                        Item.Type::Inventory:
                            JsonUtil.AddToJSon('ProductType', 'Item');
                        Item.Type::Service:
                            JsonUtil.AddToJSon('ProductType', 'Service');
                    end;
                    JsonUtil.AddToJSon('Productname', Item.Description);
                    JsonUtil.AddToJSon('Searchname', Barcodes."Barcode No.");
                    JsonUtil.AddToJSon('ItemGroupId', '100');
                    JsonUtil.AddToJSon('TrackingDimensionGroup', Item."Item Tracking Code");
                    //JsonUtil.AddToJSon('BatchNumGroupId','BAG');
                    if Item."BPC.Coverage Day" = 0 then
                        JsonUtil.AddToJSon('ReqGroupId', '14D')
                    else
                        JsonUtil.AddToJSon('ReqGroupId', StrSubstNo('%1D', Item."BPC.Coverage Day"));
                    JsonUtil.AddToJSon('PurchaseUnit', Item."Purch. Unit of Measure");
                    JsonUtil.AddToJSon('SaleUnit', Item."Sales Unit of Measure");
                    JsonUtil.AddToJSon('Inventoryunit', Item."Base Unit of Measure");
                    JsonUtil.AddToJSon('BOMunit', Item."Base Unit of Measure");
                    JsonUtil.AddToJSon('Brand', Item."LSC Item Family Code");
                    JsonUtil.AddToJSon('SubcategoryValue', Item."LSC Retail Product Code");
                    ItemUOM.Reset();
                    ItemUOM.SetRange("Item No.", Item."No.");
                    ItemUOM.SETFILTER(Code, '<>%1', Item."Base Unit of Measure");
                    if ItemUOM.FindSet() then begin
                        JsonUtil.StartJSonArray('UnitConversion');
                        repeat
                            JsonUtil.StartJSon();
                            JsonUtil.AddToJSon('FromUnit', ItemUOM.Code);
                            JsonUtil.AddToJSon('Factor', ItemUOM."Qty. per Unit of Measure");
                            JsonUtil.AddToJSon('ToUnit', Item."Base Unit of Measure");
                            JsonUtil.EndJSon();
                        until ItemUOM.Next() = 0;
                        JsonUtil.EndJSonArray;
                    end;
                    JsonUtil.EndJSon();
                end;
            'postStmtJournal':
                begin

                    PostedStmt.Get(GetFieldValue(pRecRef, 'No.'));
                    TempSalesEntry.Reset();
                    TempSalesEntry.DeleteAll();
                    SummaryTransSalesByStmt(PostedStmt."No.", TempSalesEntry, RoundingAmt, VATBase7, VATBase0, VATAmt);

                    JsonUtil.StartJSon();
                    JsonUtil.AddToJSon('Statement_No', PostedStmt."No.");
                    JsonUtil.AddToJSon('Store_No', PostedStmt."Store No.");
                    JsonUtil.AddToJSon('TransStartingDate', Format(PostedStmt."Trans. Starting Date", 0, '<Year4>-<Month,2>-<Day,2>'));
                    JsonUtil.AddToJSon('VAT_Amount', VATAmt);
                    JsonUtil.AddToJSon('Base_VAT_Amount', VATBase7);
                    JsonUtil.AddToJSon('Base_VAT_0', VATBase0);

                    TempPostedStmtLine.Reset();
                    TempPostedStmtLine.DeleteAll();
                    CheckPostedStmtLine(PostedStmt."No.", TempPostedStmtLine);
                    // PostedStmtLine.Reset();
                    // PostedStmtLine.SetRange("Statement No.", PostedStmt."No.");
                    // PostedStmtLine.SETFILTER("Trans. Amount", '<>%1', 0);
                    TempPostedStmtLine.Reset();
                    TempPostedStmtLine.SetCurrentKey("Trans. Amount");
                    TempPostedStmtLine.SetAscending("Trans. Amount", false);
                    if TempPostedStmtLine.FindSet() then begin
                        JsonUtil.StartJSonArray('PostStatementLine');
                        repeat
                            if not LSCTenderTypeSetup.Get(TempPostedStmtLine."Tender Type") then
                                LSCTenderTypeSetup.Init();
                            if not LSCTenderTypeSetup."BPC.Platform" then begin

                                Clear(TransAmt);
                                CalcStmtLine.Reset();
                                CalcStmtLine.SetRange("Statement No.", TempPostedStmtLine."Statement No.");
                                if CalcStmtLine.FindSet() then begin
                                    CalcStmtLine.CalcSums("Trans. Amount");
                                    TransAmt := CalcStmtLine."Trans. Amount";
                                    if TenderType.Get(TempPostedStmtLine."Store No.", TempPostedStmtLine."Tender Type") then begin
                                        if TenderType."BPC.POS VAT Code" <> '' then begin
                                            POSVATCode.Get(TenderType."BPC.POS VAT Code");
                                            TransAmt := ROUND((TransAmt * 100) / (100 + POSVATCode."VAT %"), 0.01);
                                        end;
                                    end;
                                end;

                                Clear(CalcTransAmt);
                                CalcTransAmt := CalcTransAmt(PostedStmt."No.", TempPostedStmtLine."Tender Type");
                                if CalcTransAmt <> 0 then begin
                                    JsonUtil.StartJSon();
                                    JsonUtil.AddToJSon('Tender_Type', TempPostedStmtLine."Tender Type");
                                    JsonUtil.AddToJSon('Reference_No', '');
                                    JsonUtil.AddToJSon('Trans_Amount', CalcTransAmt);
                                    JsonUtil.AddToJSon('Payment_term', '');
                                    JsonUtil.AddToJSon('Customer_PO', '');
                                    JsonUtil.AddToJSon('Due_Date', '');
                                    JsonUtil.AddToJSon('Reference_Document', '');
                                    JsonUtil.AddToJSon('VAT_Amount', '');
                                    JsonUtil.AddToJSon('Base_VAT_0', '');
                                    JsonUtil.AddToJSon('Base_Amount', '');

                                    TransactionHeader.Reset();
                                    TransactionHeader.SetRange("Statement No.", PostedStmt."No.");
                                    TransactionHeader.SetRange("Transaction Type", TransactionHeader."Transaction Type"::Sales);
                                    if TransactionHeader.FindSet() then begin
                                        JsonUtil.StartJSonArray('PaymentEntry');
                                        repeat
                                            VoucherEntriesTmp.Reset();
                                            //VoucherEntriesTmp.SetRange("Entry Type", VoucherEntries."Entry Type"::Issued);
                                            VoucherEntriesTmp.SetRange("Voucher Type", 'DEPOSIT');
                                            VoucherEntriesTmp.SetRange("Receipt Number", TransactionHeader."Receipt No.");
                                            if Not VoucherEntriesTmp.FindSet() then begin
                                                VoucherEntries.Reset();
                                                //VoucherEntries.SetRange("Entry Type", VoucherEntries."Entry Type"::Issued);
                                                VoucherEntries.SetRange("Voucher Type", 'DEPOSIT');
                                                VoucherEntries.SetRange("Receipt Number", TransactionHeader."Receipt No.");
                                                if VoucherEntries.FindSet() then begin
                                                    repeat
                                                        VoucherEntriesTmp.Reset();
                                                        VoucherEntriesTmp.TransferFields(VoucherEntries);
                                                        // if VoucherEntries.Amount < 0 then
                                                        //     VoucherEntriesTmp."Return Deposit" := true;
                                                        VoucherEntriesTmp."Return Deposit" := VoucherEntries."BPC.Return Deposit";
                                                        VoucherEntriesTmp.Amount := Abs(VoucherEntriesTmp.Amount);
                                                        VoucherEntriesTmp.Insert();
                                                    until VoucherEntries.Next() = 0;
                                                end;
                                            end;
                                            if not SkipReceiptVoidJournal(TransactionHeader."Store No.", TransactionHeader."POS Terminal No.", TransactionHeader."Transaction No.") then begin
                                                TransPaymentEntry.Reset();
                                                TransPaymentEntry.SetCurrentKey("Amount Tendered");
                                                TransPaymentEntry.SetRange("Store No.", TransactionHeader."Store No.");
                                                TransPaymentEntry.SetRange("POS Terminal No.", TransactionHeader."POS Terminal No.");
                                                TransPaymentEntry.SetRange("Transaction No.", TransactionHeader."Transaction No.");
                                                TransPaymentEntry.SetRange("Tender Type", TempPostedStmtLine."Tender Type");
                                                TransPaymentEntry.SetFilter("Amount Tendered", '<>%1', 0); //Joe
                                                TransPaymentEntry.SetAscending("Amount Tendered", false);
                                                if TransPaymentEntry.FindSet() then begin
                                                    if TransPaymentEntry."Tender Type" = 'CASH' then begin
                                                        // Sum and create single a object for tender type CASH
                                                        TransPaymentEntry.CalcSums("Amount Tendered");
                                                        CreateJsonPaymentEntryObject(TransPaymentEntry, VoucherEntriesTmp);
                                                    end else begin
                                                        // Create an object for each payment line
                                                        repeat
                                                            CreateJsonPaymentEntryObject(TransPaymentEntry, VoucherEntriesTmp);
                                                        until TransPaymentEntry.Next() = 0;
                                                    end;
                                                end;
                                            end;
                                        until TransactionHeader.next = 0;
                                        JsonUtil.EndJSonArray;
                                    end;
                                    JsonUtil.EndJSon();
                                end;
                            end;
                        until TempPostedStmtLine.Next() = 0;

                        TransactionHeaderDiff.Reset();
                        TransactionHeaderDiff.SetRange("Statement No.", PostedStmt."No.");
                        TransactionHeaderDiff.SetRange("Transaction Type", TransactionHeaderDiff."Transaction Type"::Sales);
                        TransactionHeaderDiff.SetFilter("Rounded", '<>0');
                        if TransactionHeaderDiff.FindSet() then begin
                            repeat
                                if not SkipReceiptVoidJournal(TransactionHeaderDiff."Store No.", TransactionHeaderDiff."POS Terminal No.", TransactionHeaderDiff."Transaction No.") then begin
                                    TransPaymentEntryDiff.Reset();
                                    TransPaymentEntryDiff.SetRange("Store No.", TransactionHeaderDiff."Store No.");
                                    TransPaymentEntryDiff.SetRange("Transaction No.", TransactionHeaderDiff."Transaction No.");
                                    TransPaymentEntryDiff.SetRange("POS Terminal No.", TransactionHeaderDiff."POS Terminal No.");
                                    TransPaymentEntryDiff.SetRange("Receipt No.", TransactionHeaderDiff."Receipt No.");
                                    TransPaymentEntryDiff.SetFilter("Tender Type", 'E-*');
                                    if not TransPaymentEntryDiff.FindSet() then begin

                                        JsonUtil.StartJSon();
                                        JsonUtil.AddToJSon('Tender_Type', 'DIFF');
                                        JsonUtil.AddToJSon('Reference_No', '');
                                        JsonUtil.AddToJSon('Trans_Amount', TransactionHeaderDiff.Rounded * -1);
                                        JsonUtil.AddToJSon('Payment_term', '');
                                        JsonUtil.AddToJSon('Customer_PO', '');
                                        JsonUtil.AddToJSon('Due_Date', '');
                                        JsonUtil.AddToJSon('Reference_Document', '');
                                        JsonUtil.AddToJSon('VAT_Amount', '');
                                        JsonUtil.AddToJSon('Base_VAT_0', '');
                                        JsonUtil.AddToJSon('Base_Amount', '');

                                        JsonUtil.StartJSonArray('PaymentEntry');
                                        JsonUtil.StartJSon();
                                        JsonUtil.AddToJSon('TenderType', 'DIFF');
                                        JsonUtil.AddToJSon('Amount', TransactionHeaderDiff.Rounded * -1);
                                        JsonUtil.AddToJSon('POS_No', TransactionHeaderDiff."POS Terminal No.");
                                        JsonUtil.AddToJSon('Transaction_no', TransactionHeaderDiff."Transaction No.");
                                        JsonUtil.AddToJSon('ApprovalCode', '');
                                        JsonUtil.AddToJSon('Receipt_No', TransactionHeaderDiff."Receipt No.");
                                        JsonUtil.AddToJSon('CN_Exchange', '');
                                        JsonUtil.AddToJSon('Deposit', '');
                                        JsonUtil.EndJSon();
                                        JsonUtil.EndJSonArray;
                                        JsonUtil.EndJSon();
                                    end;
                                end;
                            until TransactionHeaderDiff.next = 0;
                        end;

                        //เสือ
                        // if RoundingAmt <> 0 then begin
                        //     JsonUtil.StartJSon();
                        //     JsonUtil.AddToJSon('Tender_Type', 'DIFF');
                        //     JsonUtil.AddToJSon('Trans_Amount', -RoundingAmt);
                        //     JsonUtil.EndJSon();
                        // end;
                        //เสือ
                        JsonUtil.EndJSonArray;
                    end;


                    TempSalesEntry.Reset();
                    //เสือ by โอม
                    //TmpSalesEntry.SETFILTER("Net Amount", '<>%1', 0);
                    if TempSalesEntry.FindSet() then begin
                        JsonUtil.StartJSonArray('SalesEntry');
                        repeat
                            if not TransactionHeader.Get(TempSalesEntry."Store No.", TempSalesEntry."POS Terminal No.", TempSalesEntry."Transaction No.") then
                                TransactionHeader.Init();

                            VoucherEntries.Reset();
                            VoucherEntries.SetRange("Voucher Type", 'DEPOSIT');
                            VoucherEntries.SetRange("Receipt Number", TransactionHeader."Receipt No.");
                            // VoucherEntries.SetFilter("Line No.", TmpSalesEntry."BPC.Line No. Text");
                            if (VoucherEntries.FindSet()) and (TempSalesEntry."Deal Line") then begin
                                // JsonUtil.StartJSonArray('Deposit');
                                // เป็นขารับ DEPOSIT++
                                // repeat
                                JsonUtil.StartJSon();
                                JsonUtil.AddToJSon('Stroe_no', VoucherEntries."Store No.");
                                JsonUtil.AddToJSon('Location', '');
                                JsonUtil.AddToJSon('POS_No', TransactionHeader."POS Terminal No.");
                                JsonUtil.AddToJSon('Transaction_no', VoucherEntries."Transaction No.");
                                JsonUtil.AddToJSon('Item_No', TempSalesEntry."Item No.");
                                JsonUtil.AddToJSon('Receipt_No', TransactionHeader."Receipt No.");
                                if (TransactionHeader."Sale Is Return Sale") and (TransactionHeader."Retrieved from Receipt No." = '') then
                                    JsonUtil.AddToJSon('RetrivedReceiptNo', 'Refund')
                                else
                                    JsonUtil.AddToJSon('RetrivedReceiptNo', TransactionHeader."Retrieved from Receipt No.");
                                JsonUtil.AddToJSon('Sales_Order', TransactionHeader."BPC.Sales Order No.");
                                JsonUtil.AddToJSon('ReturnSales', TransactionHeader."Sale Is Return Sale");

                                //--A-- 2024/11/15 ++
                                POSDataEntry.Reset();
                                POSDataEntry.SetRange("Created by Receipt No.", TransactionHeader."Receipt No.");
                                POSDataEntry.SetRange("Created by Line No.", TempSalesEntry."Line No.");
                                if POSDataEntry.FindSet() then begin
                                    POSDataEntry.CalcSums(Amount);
                                    JsonUtil.AddToJSon('Net_Amount', TempSalesEntry."Net Amount");
                                    JsonUtil.AddToJSon('VAT_Amount', TempSalesEntry."VAT Amount");
                                    JsonUtil.AddToJSon('Deposit_No', POSDataEntry."Entry Code");
                                end else begin
                                    JsonUtil.AddToJSon('Net_Amount', TempSalesEntry."Net Amount");
                                    JsonUtil.AddToJSon('VAT_Amount', TempSalesEntry."VAT Amount");
                                    JsonUtil.AddToJSon('Deposit_No', '');
                                end;
                                //--A-- 2024/11/15 --

                                JsonUtil.EndJSon();
                                // JsonUtil.StartJSon();
                                // JsonUtil.AddToJSon('Deposit_No', VoucherEntries."Voucher No.");
                                // JsonUtil.EndJSon();
                                // until VoucherEntries.Next() = 0;
                                // เป็นขารับ DEPOSIT--
                                // JsonUtil.EndJSonArray;
                            end else begin
                                // JsonUtil.AddToJSon('Deposit', '');
                                JsonUtil.StartJSon();
                                JsonUtil.AddToJSon('Stroe_no', TempSalesEntry."Store No.");
                                JsonUtil.AddToJSon('Location', '');
                                JsonUtil.AddToJSon('POS_No', TempSalesEntry."POS Terminal No.");
                                JsonUtil.AddToJSon('Transaction_no', TempSalesEntry."Transaction No.");
                                JsonUtil.AddToJSon('Item_No', TempSalesEntry."Item No.");
                                JsonUtil.AddToJSon('Receipt_No', TransactionHeader."Receipt No.");
                                if (TransactionHeader."Sale Is Return Sale") and (TransactionHeader."Retrieved from Receipt No." = '') then
                                    JsonUtil.AddToJSon('RetrivedReceiptNo', 'Refund')
                                else
                                    JsonUtil.AddToJSon('RetrivedReceiptNo', TransactionHeader."Retrieved from Receipt No.");
                                JsonUtil.AddToJSon('Sales_Order', TransactionHeader."BPC.Sales Order No.");
                                JsonUtil.AddToJSon('ReturnSales', TransactionHeader."Sale Is Return Sale");
                                JsonUtil.AddToJSon('Net_Amount', TempSalesEntry."Net Amount");
                                JsonUtil.AddToJSon('VAT_Amount', TempSalesEntry."VAT Amount");


                                // Return ไม่ส่ง เลข Deposit
                                if TransactionHeader."Retrieved from Receipt No." = '' then begin
                                    POSDataEntry.Reset();
                                    POSDataEntry.SetRange("Applied by Receipt No.", TransactionHeader."Receipt No.");
                                    //เสือ by เก่ง
                                    POSDataEntry.SetRange("Entry Type", 'DEPOSIT');
                                    //เสือ
                                    //POSDataEntry.SetRange("BPC.Item No.", TmpSalesEntry."Item No.");
                                    if POSDataEntry.FindSet() then begin
                                        JsonUtil.StartJSonArray('Deposit');
                                        repeat
                                            JsonUtil.StartJSon();
                                            JsonUtil.AddToJSon('Deposit_No', POSDataEntry."Entry Code");
                                            JsonUtil.AddToJSon('Amount', -POSDataEntry.Amount);
                                            JsonUtil.EndJSon();
                                        until POSDataEntry.next = 0;
                                        JsonUtil.EndJSonArray;
                                    end;
                                end;

                                //--A-- 2024/11/15 --
                                JsonUtil.EndJSon();
                            end;
                        until TempSalesEntry.Next() = 0;
                        JsonUtil.EndJSonArray;
                    end;
                    JsonUtil.EndJSon();
                end;
            'postStmtMovement':
                BEGIN
                    PostedStmt.Get(GetFieldValue(RecRef, 'No.'));
                    Clear(ItemLedgerNo);
                    JsonUtil.StartJSon();
                    JsonUtil.AddToJSon('Statement_No', PostedStmt."No.");
                    JsonUtil.AddToJSon('Store_No', PostedStmt."Store No.");
                    LSCTransactionHeader.Reset();
                    LSCTransactionHeader.SetRange("Posted Statement No.", PostedStmt."No.");
                    if LSCTransactionHeader.FindSet() then begin
                        JsonUtil.StartJSonArray('PostStatementLine');
                        repeat
                            if not SkipReceiptVoid(LSCTransactionHeader."Store No.", LSCTransactionHeader."POS Terminal No.", LSCTransactionHeader."Transaction No.") then begin
                                TenderTypeEntry.Reset();
                                TenderTypeEntry.SetRange("BPC Receipt No.", LSCTransactionHeader."Receipt No.");
                                if not TenderTypeEntry.FindSet() then
                                    TenderTypeEntry.init;

                                if not LSCTenderTypeSetup.Get(TenderTypeEntry."BPC Tender Type") then
                                    LSCTenderTypeSetup.Init();
                                //joe
                                if not LSCTenderTypeSetup."BPC.Platform" then begin
                                    i := 0;
                                    Bomi := 0;
                                    ItemLedgerNo := StrSubstNo('%1-%2-%3', LSCTransactionHeader."Store No.", LSCTransactionHeader."POS Terminal No.", LSCTransactionHeader."Transaction No.");
                                    LedgEntry.Reset();
                                    LedgEntry.SetRange("Document No.", ItemLedgerNo);
                                    LedgEntry.SetRange("Entry Type", LedgEntry."Entry Type"::Sale);
                                    if LedgEntry.FindSet() then begin
                                        repeat
                                            IF NOT Item.Get(LedgEntry."Item No.") THEN
                                                Item.Init();
                                            IF NOT ItemTracking.Get(Item."Item Tracking Code") THEN
                                                ItemTracking.Init();
                                            if LedgEntry."Item No." = 'DS' then begin
                                                Clear(CountLineJSon);
                                                repeat
                                                    i += 1;
                                                    if i = 2 then begin
                                                        JsonUtil.EndJSon; //ถ้าledgentryมีมากกว่า 1 รายการ ให้EndJSonรอบที่2
                                                        i := 1;
                                                    end;

                                                    CountLineJSon += 1;

                                                    JsonUtil.StartJSon();
                                                    JsonUtil.AddToJSon('EntryNo', LedgEntry."Entry No.");
                                                    JsonUtil.AddToJSon('Transaction_No', LSCTransactionHeader."Transaction No.");
                                                    JsonUtil.AddToJSon('Location', LedgEntry."Location Code");
                                                    JsonUtil.AddToJSon('Item_No', LedgEntry."Item No.");

                                                    if LedgEntry.Quantity < 0 then
                                                        JsonUtil.AddToJSon('Quantity', -1)
                                                    else
                                                        JsonUtil.AddToJSon('Quantity', 1);

                                                    JsonUtil.AddToJSon('Unit_of_Measure', LedgEntry."Unit of Measure Code");
                                                    JsonUtil.AddToJSon('Variant_Code', LedgEntry."Variant Code");
                                                    JsonUtil.AddToJSon('Sales_Order', LSCTransactionHeader."BPC.Sales Order No.");
                                                    IF (ItemTracking."SN Specific Tracking") THEN BEGIN
                                                        JsonUtil.AddToJSon('Serial_No', LedgEntry."Serial No.")
                                                    END else
                                                        JsonUtil.AddToJSon('Serial_No', '');
                                                    IF (ItemTracking."Lot Specific Tracking") THEN BEGIN
                                                        IF ItemTracking."BPC.Lot Default to ERP" = '' THEN
                                                            JsonUtil.AddToJSon('Batch_No', LedgEntry."Lot No.")
                                                        ELSE
                                                            JsonUtil.AddToJSon('Batch_No', ItemTracking."BPC.Lot Default to ERP");
                                                    END ELSE
                                                        IF ItemTracking."BPC.Lot Default to ERP" <> '' THEN
                                                            JsonUtil.AddToJSon('Batch_No', ItemTracking."BPC.Lot Default to ERP")
                                                        ELSE
                                                            JsonUtil.AddToJSon('Batch_No', '');

                                                    JsonUtil.AddToJSon('SalesTransDate', FORMAT(LedgEntry."Posting Date", 0, '<Year4>-<Month,2>-<Day,2>'))
                                                until CountLineJSon = ABS(LedgEntry.Quantity);
                                            end else begin
                                                i += 1;
                                                if i = 2 then begin
                                                    JsonUtil.EndJSon; //ถ้าledgentryมีมากกว่า 1 รายการ ให้EndJSonรอบที่2
                                                    i := 1;
                                                end;

                                                JsonUtil.StartJSon();
                                                JsonUtil.AddToJSon('EntryNo', LedgEntry."Entry No.");
                                                JsonUtil.AddToJSon('Transaction_No', LSCTransactionHeader."Transaction No.");
                                                JsonUtil.AddToJSon('POS_No', LSCTransactionHeader."POS Terminal No.");
                                                JsonUtil.AddToJSon('Location', LedgEntry."Location Code");
                                                JsonUtil.AddToJSon('Item_No', LedgEntry."Item No.");
                                                JsonUtil.AddToJSon('Quantity', LedgEntry.Quantity);
                                                JsonUtil.AddToJSon('Unit_of_Measure', LedgEntry."Unit of Measure Code");
                                                JsonUtil.AddToJSon('Variant_Code', LedgEntry."Variant Code");
                                                JsonUtil.AddToJSon('Sales_Order', LSCTransactionHeader."BPC.Sales Order No.");
                                                IF (ItemTracking."SN Specific Tracking") THEN BEGIN
                                                    JsonUtil.AddToJSon('Serial_No', LedgEntry."Serial No.")
                                                END else
                                                    JsonUtil.AddToJSon('Serial_No', '');
                                                IF (ItemTracking."Lot Specific Tracking") THEN BEGIN
                                                    IF ItemTracking."BPC.Lot Default to ERP" = '' THEN
                                                        JsonUtil.AddToJSon('Batch_No', LedgEntry."Lot No.")
                                                    ELSE
                                                        JsonUtil.AddToJSon('Batch_No', ItemTracking."BPC.Lot Default to ERP");
                                                END ELSE
                                                    IF ItemTracking."BPC.Lot Default to ERP" <> '' THEN
                                                        JsonUtil.AddToJSon('Batch_No', ItemTracking."BPC.Lot Default to ERP")
                                                    ELSE
                                                        JsonUtil.AddToJSon('Batch_No', '');

                                                JsonUtil.AddToJSon('SalesTransDate', FORMAT(LedgEntry."Posting Date", 0, '<Year4>-<Month,2>-<Day,2>'))
                                            end;

                                            if (Item."LSC Recipe Item Type" = Item."LSC Recipe Item Type"::Recipe) and (LedgEntry."Entry Type" = LedgEntry."Entry Type"::Sale) then begin
                                                TransSalesEntry.Reset();
                                                TransSalesEntry.SetRange("Store No.", LSCTransactionHeader."Store No.");
                                                TransSalesEntry.SetRange("POS Terminal No.", LSCTransactionHeader."POS Terminal No.");
                                                TransSalesEntry.SetRange("Transaction No.", LSCTransactionHeader."Transaction No.");
                                                TransSalesEntry.SetRange("Parent Item No.", LedgEntry."Item No.");
                                                if TransSalesEntry.FindSet() then begin
                                                    // if Bomi = 1 then
                                                    JsonUtil.StartJSonArray('BOM'); //สร้างJSon BOM
                                                    repeat
                                                        //Bomi += 1;
                                                        JsonUtil.StartJSon();
                                                        JsonUtil.AddToJSon('Item_No', TransSalesEntry."Item No.");
                                                        JsonUtil.AddToJSon('Quantity', TransSalesEntry.Quantity);
                                                        JsonUtil.AddToJSon('Unit_of_Measure', TransSalesEntry."Unit of Measure");
                                                        JsonUtil.EndJSon;
                                                    until TransSalesEntry.next() = 0;
                                                    JsonUtil.EndJSonArray;
                                                end;
                                                //joe
                                            end else begin
                                                if LedgEntry."Entry Type" = LedgEntry."Entry Type"::Sale then begin
                                                    // if Bomi <> 0 then begin
                                                    //     JsonUtil.EndJSonArray; //EndJSonArrayรายการ Bom
                                                    //     Bomi := 0;
                                                    // end;

                                                    //ถ้าเป็น Item Deposit ให้แยกรายการตาม Quantity

                                                end;
                                            end;
                                        until LedgEntry.Next() = 0;
                                        if Bomi <> 0 then begin
                                            JsonUtil.EndJSonArray; //EndJSonArrayรายการ Bom รายการสุดท้าย
                                            Bomi := 0;
                                        end;
                                        JsonUtil.EndJSon; //EndJSon รายการสุดท้าย
                                    end;
                                end;
                            end;
                        until LSCTransactionHeader.Next() = 0;
                        JsonUtil.EndJSonArray;
                    end;
                    JsonUtil.EndJSon;
                    //Old Joe
                    // if (LedgEntry."Entry Type" = LedgEntry."Entry Type"::Sale) then
                    //     Bomi += 1;
                    //     if Bomi = 1 then
                    //         JsonUtil.StartJSonArray('BOM'); //สร้างJSon BOM
                    //     JsonUtil.StartJSon();
                    //     JsonUtil.AddToJSon('Item_No', LedgEntry."Item No.");
                    //     JsonUtil.AddToJSon('Quantity', LedgEntry.Quantity);
                    //     JsonUtil.AddToJSon('Unit_of_Measure', LedgEntry."Unit of Measure Code");
                    //     JsonUtil.EndJSon;
                    //joe
                END;
            'PostSalesShipment':
                BEGIN
                    SalesHeader.RESET;
                    SalesHeader.SETFILTER("Document Type", GetFieldValue(RecRef, 'Document Type'));
                    SalesHeader.SETFILTER("No.", GetFieldValue(RecRef, 'No.'));
                    IF SalesHeader.FINDSET THEN BEGIN
                        SalesShipmentHeader.RESET;
                        SalesShipmentHeader.SetRange("Order No.", SalesHeader."No.");
                        IF SalesShipmentHeader.FINDSET THEN BEGIN
                            JsonUtil.StartJSon;
                            if not Customer.get(SalesShipmentHeader."Sell-to Customer No.") then
                                Customer.init;
                            // Header
                            JsonUtil.AddToJSon('SOH_SONo', SalesShipmentHeader."Order No.");
                            JsonUtil.AddToJSon('SOH_CustShipNo', SalesShipmentHeader."No.");
                            JsonUtil.AddToJSon('SOH_SellToCustNo', SalesShipmentHeader."Sell-to Customer No.");
                            JsonUtil.AddToJSon('SOH_PostingDate', Format(SalesShipmentHeader."Posting Date", 0, '<Year4>-<Month,2>-<Day,2>'));
                            JsonUtil.AddToJSon('SOH_DocumentDate', Format(SalesShipmentHeader."Document Date", 0, '<Year4>-<Month,2>-<Day,2>'));
                            JsonUtil.AddToJSon('SOH_CustName', Customer.Name);
                            if Customer."VAT Registration No." <> '' then
                                JsonUtil.AddToJSon('SOH_VATRegistrationNo', Customer."VAT Registration No.");
                            JsonUtil.AddToJSon('SOH_FullTaxNo', '');
                            JsonUtil.AddToJSon('SOH_HeadOffice', Customer."BPC Head Office");
                            JsonUtil.AddToJSon('SOH_BranchNo', Customer."BPC Branch No.");
                            JsonUtil.AddToJSon('SOH_Date', Format(SalesShipmentHeader."Document Date", 0, '<Year4>-<Month,2>-<Day,2>'));

                            JsonUtil.AddToJSon('SOH_InvoiceName', Customer."Name");
                            JsonUtil.AddToJSon('SOH_InvoiceAddress', Customer."Address");
                            JsonUtil.AddToJSon('SOH_InvoiceAddress2', Customer."Address 2".Replace(' ', ','));
                            JsonUtil.AddToJSon('SOH_InvoiceCity', Customer."City");
                            // JsonUtil.AddToJSon('SOH_InvoiceCountry', Customer."Country/Region Code");
                            if (Customer."Country/Region Code" = 'TH') or (Customer."Country/Region Code" = '') then
                                JsonUtil.AddToJSon('SOH_InvoiceCountry', 'THA')
                            else
                                JsonUtil.AddToJSon('SOH_InvoiceCountry', Customer."Country/Region Code");

                            JsonUtil.AddToJSon('SOH_InvoicePostalCode', Customer."Post Code");
                            // Line
                            SalesShipmentLine.RESET;
                            SalesShipmentLine.SETRANGE("Document No.", SalesShipmentHeader."No.");
                            SalesShipmentLine.SETFILTER(Quantity, '<>%1', 0);
                            IF SalesShipmentLine.FINDSET THEN BEGIN
                                TmpItemLedgerEntry.DeleteAll();
                                Clear(ShipmentLine);
                                Clear(CheckDocShipmentLine);
                                JsonUtil.StartJSonArray('SOLine');
                                REPEAT
                                    JsonUtil.StartJSon;
                                    // if CheckDocShipmentLine <> SalesShipmentLine."No." then begin
                                    //     CheckDocShipmentLine := SalesShipmentLine."No.";
                                    //     ShipmentLine += 10000;
                                    // end;
                                    JsonUtil.AddToJSon('SOL_LineNo', SalesShipmentLine."Line No.");
                                    JsonUtil.AddToJSon('SOL_ItemNo', SalesShipmentLine."No.");
                                    JsonUtil.AddToJSon('SOL_Warehouse', SalesShipmentLine."Location Code");
                                    JsonUtil.AddToJSon('SOL_QTYtopacking', SalesShipmentLine.Quantity);
                                    JsonUtil.AddToJSon('SOL_Batch', '');
                                    ItemEntryRelation.SetCurrentKey("Source ID", "Source Type");
                                    ItemEntryRelation.SetRange("Source Type", Database::"Sales Shipment Line");
                                    ItemEntryRelation.SetRange("Source Subtype", 0);
                                    ItemEntryRelation.SetRange("Source ID", SalesShipmentLine."Document No.");
                                    ItemEntryRelation.SetRange("Source Ref. No.", SalesShipmentLine."Line No.");
                                    if ItemEntryRelation.FindSet() then begin
                                        JsonUtil.StartJSonArray('SOL_Serial');
                                        repeat
                                            ItemLedgerEntry.Reset();
                                            ItemLedgerEntry.SetRange("Entry No.", ItemEntryRelation."Item Entry No.");
                                            if ItemLedgerEntry.FindSet() then begin
                                                JsonUtil.StartJSon;
                                                JsonUtil.AddToJSon('Serial_ItemNo', SalesShipmentLine."No.");
                                                JsonUtil.AddToJSon('Serial_No', ItemLedgerEntry."Serial No.");
                                                if SalesShipmentLine.Quantity >= 0 then
                                                    JsonUtil.AddToJSon('Serial_Qty', Abs(ItemLedgerEntry.Quantity))
                                                else begin
                                                    if ItemLedgerEntry.Quantity < 0 then
                                                        JsonUtil.AddToJSon('Serial_Qty', ItemLedgerEntry.Quantity)
                                                    else
                                                        JsonUtil.AddToJSon('Serial_Qty', -ItemLedgerEntry.Quantity);
                                                end;
                                                AssembletoOrderLink.Reset();
                                                AssembletoOrderLink.SetRange("Document No.", SalesShipmentHeader."Order No.");
                                                AssembletoOrderLink.SetRange("Document Line No.", SalesShipmentLine."Line No.");
                                                AssembletoOrderLink.SetRange("Assembly Document Type", AssembletoOrderLink."Assembly Document Type"::Order);
                                                if AssembletoOrderLink.FINDSET then begin
                                                    PostedAssemblyLine.Reset();
                                                    PostedAssemblyLine.SetRange("Order No.", AssembletoOrderLink."Assembly Document No.");
                                                    if PostedAssemblyLine.FindSet() then begin
                                                        JsonUtil.StartJSonArray('SOL_SerialBOM');
                                                        repeat
                                                            ItemLedgerEntrySerial.Reset();
                                                            ItemLedgerEntrySerial.SetRange("Document No.", PostedAssemblyLine."Document No.");
                                                            ItemLedgerEntrySerial.SetRange("Document Type", ItemLedgerEntrySerial."Document Type"::"Posted Assembly");
                                                            ItemLedgerEntrySerial.SetRange("Item No.", PostedAssemblyLine."No.");
                                                            if ItemLedgerEntrySerial.FindSet() then begin
                                                                repeat
                                                                    JsonUtil.StartJSon;
                                                                    JsonUtil.AddToJSon('bomSerial', ItemLedgerEntrySerial."Serial No.");
                                                                    JsonUtil.AddToJSon('bombatch', '');
                                                                    JsonUtil.AddToJSon('bomItemNo', ItemLedgerEntrySerial."Item No.");
                                                                    JsonUtil.AddToJSon('bomLineNo', PostedAssemblyLine."Line No.");
                                                                    if SalesShipmentLine.Quantity >= 0 then
                                                                        JsonUtil.AddToJSon('bomQuantity', Abs(ItemLedgerEntrySerial.Quantity))
                                                                    else begin
                                                                        if ItemLedgerEntry.Quantity < 0 then
                                                                            JsonUtil.AddToJSon('bomQuantity', ItemLedgerEntrySerial.Quantity)
                                                                        else
                                                                            JsonUtil.AddToJSon('bomQuantity', -ItemLedgerEntrySerial.Quantity);
                                                                    end;
                                                                    JsonUtil.EndJSon;
                                                                // end;
                                                                until ItemLedgerEntrySerial.next = 0;
                                                            end;
                                                        until PostedAssemblyLine.next = 0;
                                                        JsonUtil.EndJSonArray;
                                                    end;
                                                end;
                                                JsonUtil.EndJSon;
                                            end;
                                        until ItemEntryRelation.Next() = 0;
                                        JsonUtil.EndJSonArray;
                                    end else begin
                                        JsonUtil.StartJSonArray('SOL_Serial');
                                        JsonUtil.StartJSon;
                                        JsonUtil.AddToJSon('Serial_ItemNo', SalesShipmentLine."No.");
                                        JsonUtil.AddToJSon('Serial_No', '');
                                        JsonUtil.AddToJSon('Serial_Qty', SalesShipmentLine.Quantity);
                                        AssembletoOrderLink.Reset();
                                        AssembletoOrderLink.SetRange("Document No.", SalesShipmentHeader."Order No.");
                                        AssembletoOrderLink.SetRange("Document Line No.", SalesShipmentLine."Line No.");
                                        AssembletoOrderLink.SetRange("Assembly Document Type", AssembletoOrderLink."Assembly Document Type"::Order);
                                        if AssembletoOrderLink.FINDSET then begin
                                            PostedAssemblyLine.Reset();
                                            PostedAssemblyLine.SetRange("Order No.", AssembletoOrderLink."Assembly Document No.");
                                            if PostedAssemblyLine.FindSet() then begin
                                                JsonUtil.StartJSonArray('SOL_SerialBOM');
                                                repeat
                                                    ItemLedgerEntrySerial.Reset();
                                                    ItemLedgerEntrySerial.SetRange("Document No.", PostedAssemblyLine."Document No.");
                                                    ItemLedgerEntrySerial.SetRange("Document Type", ItemLedgerEntrySerial."Document Type"::"Posted Assembly");
                                                    ItemLedgerEntrySerial.SetRange("Item No.", PostedAssemblyLine."No.");
                                                    if ItemLedgerEntrySerial.FindSet() then begin
                                                        repeat
                                                            JsonUtil.StartJSon;
                                                            JsonUtil.AddToJSon('bomSerial', ItemLedgerEntrySerial."Serial No.");
                                                            JsonUtil.AddToJSon('bombatch', '');
                                                            JsonUtil.AddToJSon('bomItemNo', ItemLedgerEntrySerial."Item No.");
                                                            JsonUtil.AddToJSon('bomLineNo', PostedAssemblyLine."Line No.");
                                                            if SalesShipmentLine.Quantity >= 0 then
                                                                JsonUtil.AddToJSon('bomQuantity', Abs(ItemLedgerEntrySerial.Quantity))
                                                            else begin
                                                                if ItemLedgerEntry.Quantity < 0 then
                                                                    JsonUtil.AddToJSon('bomQuantity', ItemLedgerEntrySerial.Quantity)
                                                                else
                                                                    JsonUtil.AddToJSon('bomQuantity', -ItemLedgerEntrySerial.Quantity);
                                                            end;
                                                            JsonUtil.EndJSon;
                                                        // end;
                                                        until ItemLedgerEntrySerial.next = 0;
                                                    end;
                                                until PostedAssemblyLine.next = 0;
                                                JsonUtil.EndJSonArray;
                                            end;
                                        end;
                                        JsonUtil.EndJSon;
                                        JsonUtil.EndJSonArray;
                                    end;
                                    JsonUtil.EndJSon;
                                UNTIL SalesShipmentLine.NEXT = 0;
                                JsonUtil.EndJSonArray;
                            END;
                            JsonUtil.EndJSon
                        END;
                    END;
                END;
            'PostItemJournal':
                begin
                    if EVALUATE(lnWorksheetSeqNo, GetFieldValue(pRecRef, 'WorksheetSeqNo')) then;
                    TMPItemLedgEntry.Reset();
                    TMPItemLedgEntry.SetCurrentKey("Entry No.");
                    TMPItemLedgEntry.SetRange("User ID", UserId);
                    TMPItemLedgEntry.SetFilter("Entry Type", '<>%1', TMPItemLedgEntry."Entry Type"::Transfer);
                    if TMPItemLedgEntry.FindSet() then begin
                        repeat
                            ItemLedgerEnt.Reset();
                            ItemLedgerEnt.SetRange("Document No.", TMPItemLedgEntry."Document No.");
                            ItemLedgerEnt.SetRange("Entry No.", TMPItemLedgEntry."Entry No.");
                            if ItemLedgerEnt.FindSet() then begin
                                JsonUtil.StartJSonArray('');
                                JsonUtil.StartJSon();
                                JsonUtil.AddToJSon('ReasonCode', TMPItemLedgEntry."Reason Code");
                                JsonUtil.AddToJSon('DocumentNumber', ItemLedgerEnt."Document No.");
                                JsonUtil.AddToJSon('PostedDate', Format(ItemLedgerEnt."Posting Date", 0, '<Year4>-<Month,2>-<Day,2>'));
                                JsonUtil.AddToJSon('Warehouse', ItemLedgerEnt."Location Code");
                                JsonUtil.AddToJSon('ItemNumber', ItemLedgerEnt."Item No.");
                                JsonUtil.AddToJSon('Quantity', ItemLedgerEnt.Quantity);
                                JsonUtil.AddToJSon('Unit', ItemLedgerEnt."Unit of Measure Code");
                                JsonUtil.StartJSonArray('BatchNumber');
                                JsonUtil.StartJSon();
                                JsonUtil.AddToJSon('Lot_No', ItemLedgerEnt."Lot No.");
                                JsonUtil.EndJSon();
                                JsonUtil.EndJSonArray;
                                JsonUtil.StartJSonArray('SerialNumber');
                                JsonUtil.StartJSon();
                                JsonUtil.AddToJSon('Serial_No', ItemLedgerEnt."Serial No.");
                                JsonUtil.AddToJSon('Serial_Qty', ItemLedgerEnt.Quantity);
                                JsonUtil.EndJSon();
                                JsonUtil.EndJSonArray;
                                JsonUtil.EndJSon();
                                JsonUtil.EndJSonArray;
                            end;
                        until TMPItemLedgEntry.Next() = 0;
                    end;
                end;
        end;
        EXIT(JsonUtil.GetJSon());
    end;


    procedure CreateJsonJournal(SelectionFunctions: Text): Text
    var
        dd: Record 336;
        //ItemJournalLine: Record "Item Journal Line";
        ReservationEntry:
                Record "Reservation Entry";
        TMPItemLedgEntry:
                Record "BPC.TMPItemLedgEntry";
        ItemLedgerEnt:
                Record "Item Ledger Entry";
        ItemLedgerEntFrom:
                Record "Item Ledger Entry";
        ItemLedgerEntto:
                Record "Item Ledger Entry";
        SerialNoFrom:
                Text;
        SerialNoTo:
                text;
        BatchNoFrom:
                text;
        BatchNoTo:
                text;
        FromLocation:
                text;
        ToLocation:
                text;
        LineNo:
                Integer;
    begin
        Clear(JsonUtil);
        case SelectionFunctions of
            'PostTransferJournal':
                begin
                    Clear(LineNo);
                    Clear(FromLocation);
                    Clear(ToLocation);
                    TMPItemLedgEntry.Reset();
                    TMPItemLedgEntry.SetCurrentKey("Entry No.");
                    TMPItemLedgEntry.SetRange("User ID", UserId);
                    TMPItemLedgEntry.SetRange("Entry Type", TMPItemLedgEntry."Entry Type"::Transfer);
                    TMPItemLedgEntry.SetFilter(QTY, '>%1', 0);
                    if TMPItemLedgEntry.FindSet() then begin
                        //From
                        ItemLedgerEntFrom.Reset();
                        ItemLedgerEntFrom.SetRange("Document No.", TMPItemLedgEntry."Document No.");
                        ItemLedgerEntFrom.SetRange("Location Code", TMPItemLedgEntry."BPC.Location code");
                        ItemLedgerEntFrom.SetRange("Item No.", TMPItemLedgEntry."Item No.");
                        ItemLedgerEntFrom.SetRange("Entry No.", TMPItemLedgEntry."Entry No." - 1);
                        if ItemLedgerEntFrom.FindSet() then begin
                            FromLocation := ItemLedgerEntFrom."Location Code";
                        end;
                        //TO
                        ItemLedgerEntto.Reset();
                        ItemLedgerEntto.SetRange("Document No.", TMPItemLedgEntry."Document No.");
                        ItemLedgerEntto.SetRange("Location Code", TMPItemLedgEntry."BPC.New Location code");
                        ItemLedgerEntto.SetRange("Item No.", TMPItemLedgEntry."Item No.");
                        ItemLedgerEntto.SetRange("Entry No.", TMPItemLedgEntry."Entry No.");
                        if ItemLedgerEntto.FindSet() then begin
                            ToLocation := ItemLedgerEntto."Location Code";
                        end;
                        //JsonUtil.StartJSonArray('');
                        JsonUtil.StartJSon();
                        // Header
                        JsonUtil.AddToJSon('StoreIvH_DocumentNo', TMPItemLedgEntry."Document No.");
                        JsonUtil.AddToJSon('StoreIvH_ReasonCode', TMPItemLedgEntry."Reason Code");
                        JsonUtil.AddToJSon('StoreIvH_FromLocation', FromLocation);
                        JsonUtil.AddToJSon('StoreIvH_ToLocation', ToLocation);
                        JsonUtil.StartJSonArray('StoreIvL');
                        repeat

                            Clear(SerialNoFrom);
                            Clear(SerialNoTo);
                            Clear(BatchNoFrom);
                            Clear(BatchNoTo);
                            LineNo += 10000;
                            //From
                            ItemLedgerEntFrom.Reset();
                            ItemLedgerEntFrom.SetRange("Document No.", TMPItemLedgEntry."Document No.");
                            ItemLedgerEntFrom.SetRange("Location Code", TMPItemLedgEntry."BPC.Location code");
                            ItemLedgerEntFrom.SetRange("Item No.", TMPItemLedgEntry."Item No.");
                            ItemLedgerEntFrom.SetRange("Entry No.", TMPItemLedgEntry."Entry No." - 1);
                            if ItemLedgerEntFrom.FindSet() then begin
                                SerialNoFrom := ItemLedgerEntFrom."Serial No.";
                                BatchNoFrom := ItemLedgerEntFrom."LSC Batch No.";
                            end;
                            //TO
                            ItemLedgerEntto.Reset();
                            ItemLedgerEntto.SetRange("Document No.", TMPItemLedgEntry."Document No.");
                            ItemLedgerEntto.SetRange("Location Code", TMPItemLedgEntry."BPC.New Location code");
                            ItemLedgerEntto.SetRange("Item No.", TMPItemLedgEntry."Item No.");
                            ItemLedgerEntto.SetRange("Entry No.", TMPItemLedgEntry."Entry No.");
                            if ItemLedgerEntto.FindSet() then begin
                                SerialNoTo := ItemLedgerEntto."Serial No.";
                                BatchNoTo := ItemLedgerEntto."LSC Batch No.";
                            end;
                            //line
                            ItemLedgerEnt.Reset();
                            ItemLedgerEnt.SetRange("Document No.", TMPItemLedgEntry."Document No.");
                            ItemLedgerEnt.SetRange("Entry No.", TMPItemLedgEntry."Entry No.");
                            if ItemLedgerEnt.FindSet() then begin

                                JsonUtil.StartJSon();
                                JsonUtil.AddToJSon('StoreIvL_LineNo', LineNo);
                                JsonUtil.AddToJSon('StoreIvL_PostingDate', Format(ItemLedgerEnt."Posting Date", 0, '<Year4>-<Month,2>-<Day,2>'));
                                JsonUtil.AddToJSon('StoreIvL_ItemNo', ItemLedgerEnt."Item No.");
                                JsonUtil.AddToJSon('StoreIvL_Variant', '');
                                JsonUtil.AddToJSon('StoreIvL_SerialNo', SerialNoFrom);
                                JsonUtil.AddToJSon('StoreIvL_SerialNoTo', SerialNoTo);
                                JsonUtil.AddToJSon('StoreIvL_BatchNo', BatchNoFrom);
                                JsonUtil.AddToJSon('StoreIvL_BatchNoTo', BatchNoTo);
                                JsonUtil.AddToJSon('StoreIvL_Quantity', ItemLedgerEnt.Quantity);
                                JsonUtil.AddToJSon('StoreIvL_Unit', ItemLedgerEnt."Unit of Measure Code");
                                JsonUtil.EndJSon();
                            end;
                        until TMPItemLedgEntry.Next() = 0;
                        JsonUtil.EndJSonArray;
                        JsonUtil.EndJSon();
                        //JsonUtil.EndJSonArray;
                    end;
                end;
            'PostItemJournal':
                begin
                    TMPItemLedgEntry.Reset();
                    TMPItemLedgEntry.SetCurrentKey("Entry No.");
                    TMPItemLedgEntry.SetRange("User ID", UserId);
                    // TMPItemLedgEntry.SetRange("Entry Type", TMPItemLedgEntry."Entry Type"::"Positive Adjmt.");
                    if TMPItemLedgEntry.FindSet() then begin
                        repeat
                            if (TMPItemLedgEntry."Entry Type" = TMPItemLedgEntry."Entry Type"::"Positive Adjmt.") or (TMPItemLedgEntry."Entry Type" = TMPItemLedgEntry."Entry Type"::"Negative Adjmt.") then begin
                                ItemLedgerEnt.SetRange("Document No.", TMPItemLedgEntry."Document No.");
                                ItemLedgerEnt.SetRange("Entry No.", TMPItemLedgEntry."Entry No.");
                                if ItemLedgerEnt.FindSet() then begin
                                    JsonUtil.StartJSonArray('');
                                    JsonUtil.StartJSon();
                                    JsonUtil.AddToJSon('ReasonCode', TMPItemLedgEntry."Reason Code");
                                    JsonUtil.AddToJSon('DocumentNumber', ItemLedgerEnt."Document No.");
                                    JsonUtil.AddToJSon('PostedDate', Format(ItemLedgerEnt."Posting Date", 0, '<Year4>-<Month,2>-<Day,2>'));
                                    JsonUtil.AddToJSon('Warehouse', ItemLedgerEnt."Location Code");
                                    JsonUtil.AddToJSon('ItemNumber', ItemLedgerEnt."Item No.");
                                    JsonUtil.AddToJSon('Quantity', ItemLedgerEnt.Quantity);
                                    JsonUtil.AddToJSon('Unit', ItemLedgerEnt."Unit of Measure Code");
                                    JsonUtil.StartJSonArray('BatchNumber');
                                    JsonUtil.StartJSon();
                                    JsonUtil.AddToJSon('Lot_No', ItemLedgerEnt."Lot No.");
                                    JsonUtil.EndJSon();
                                    JsonUtil.EndJSonArray;
                                    JsonUtil.StartJSonArray('SerialNumber');
                                    JsonUtil.StartJSon();
                                    JsonUtil.AddToJSon('Serial_No', ItemLedgerEnt."Serial No.");
                                    JsonUtil.AddToJSon('Serial_Qty', ItemLedgerEnt.Quantity);
                                    JsonUtil.EndJSon();
                                    JsonUtil.EndJSonArray;
                                    JsonUtil.EndJSon();
                                    JsonUtil.EndJSonArray;
                                end;
                            end;
                        until TMPItemLedgEntry.Next() = 0;
                    end;
                end;
        end;
        EXIT(JsonUtil.GetJSon());
    end;

    local procedure GetFieldValue(pRecRef: RecordRef; pFieldName: Text[50]): Text
    var
        lFieldRef: FieldRef;
    begin
        lFieldRef := pRecRef.FIELD(FindFieldNoByFieldName(pRecRef.NUMBER, pFieldName));
        EXIT(FORMAT(lFieldRef.VALUE));
    end;

    local procedure FindFieldNoByFieldName(pTableNo: Integer; pFieldName: Text[50]): Integer
    var
        FieldRec: Record "Field";
    begin
        //FindFieldNoByFieldName
        FieldRec.Reset();
        FieldRec.SetRange(TableNo, pTableNo);
        FieldRec.SetRange(FieldName, pFieldName);
        if FieldRec.FINDFIRST then
            EXIT(FieldRec."No.")
        else
            EXIT(0);
    end;


    procedure InsertInterfaceLog(pFunctionsName: Text[50]; pJsonRequestD365: Text; pURL: Text; pD365Response: Text; pDocNo: Text; pError: Boolean)
    var
        InterfaceLogDRL: Record "BPC.Interface Log API";
    begin
        case TRUE of
            (pFunctionsName = 'GetToken'):
                begin
                    InterfaceLogDRL.Reset();
                    InterfaceLogDRL.SETFILTER("BPC.Interface Type", '%1', pFunctionsName);
                    InterfaceLogDRL.SETFILTER("BPC.Document No.", '%1', 'T0001');
                    if NOT InterfaceLogDRL.FINDFIRST then begin
                        InterfaceLogDRL.Init();
                        InterfaceLogDRL."BPC.Interface Type" := pFunctionsName;
                        InterfaceLogDRL."BPC.Document No." := 'T0001';
                        InterfaceLogDRL."BPC.Entry No." := InterfaceLogDRL.RunEntryNo(pFunctionsName, InterfaceLogDRL."BPC.Document No.");
                        InterfaceLogDRL."BPC.Interface URL" := pURL;
                        InterfaceLogDRL."BPC.Interface Date" := TODAY;
                        InterfaceLogDRL."BPC.Interface Time" := TIME;
                        InterfaceLogDRL."BPC.Interface DateTime" := CREATEDATETIME(TODAY, TIME);
                        InterfaceLogDRL."BPC.Error Occur" := pError;
                        InterfaceLogDRL.Insert();
                        InterfaceLogDRL.SetRequestD365(pJsonRequestD365, TEXTENCODING::UTF8);
                        InterfaceLogDRL.SetD365Response(pD365Response, TEXTENCODING::UTF8);
                    end else begin
                        InterfaceLogDRL."BPC.Interface Date" := TODAY;
                        InterfaceLogDRL."BPC.Interface Time" := TIME;
                        InterfaceLogDRL."BPC.Interface DateTime" := CREATEDATETIME(TODAY, TIME);
                        InterfaceLogDRL."BPC.Error Occur" := pError;
                        InterfaceLogDRL.MODIFY;
                        InterfaceLogDRL.SetRequestD365(pJsonRequestD365, TEXTENCODING::UTF8);
                        InterfaceLogDRL.SetD365Response(pD365Response, TEXTENCODING::UTF8);
                    end;
                end;
            else begin
                InterfaceLogDRL.Init();
                InterfaceLogDRL."BPC.Interface Type" := pFunctionsName;
                InterfaceLogDRL."BPC.Entry No." := InterfaceLogDRL.RunEntryNo(pFunctionsName, pDocNo);
                InterfaceLogDRL."BPC.Document No." := pDocNo;
                InterfaceLogDRL."BPC.Interface URL" := pURL;
                InterfaceLogDRL."BPC.User ID" := USERID;
                InterfaceLogDRL."BPC.Interface Date" := TODAY;
                InterfaceLogDRL."BPC.Interface Time" := TIME;
                InterfaceLogDRL."BPC.Interface DateTime" := CREATEDATETIME(TODAY, TIME);
                InterfaceLogDRL."BPC.Error Occur" := pError;
                InterfaceLogDRL.Insert();
                InterfaceLogDRL.SetRequestD365(pJsonRequestD365, TEXTENCODING::UTF8);
                InterfaceLogDRL.SetD365Response(pD365Response, TEXTENCODING::UTF8);
                Clear(DocumentNo);
            end;
        end;
        Commit();
    end;

    local procedure ReplaceString(String: Text; FindWhat: Text; ReplaceWith: Text) NewString: Text
    begin
        WHILE STRPOS(String, FindWhat) > 0 DO
            String := DELSTR(String, STRPOS(String, FindWhat)) + ReplaceWith + COPYSTR(String, STRPOS(String, FindWhat) + STRLEN(FindWhat));
        NewString := String;
    end;

    local procedure InsertPostedStoreInventoryLine(pWorksheetSeqNo: Integer; pTransferJournalID: Code[20])
    begin
        StoreInventoryLine.Reset();
        StoreInventoryLine.SetRange(WorksheetSeqNo, pWorksheetSeqNo);
        if StoreInventoryLine.FindSet() then begin
            repeat
                PostedStoreInventoryLine.Init();
                PostedStoreInventoryLine.TransferFields(StoreInventoryLine);
                PostedStoreInventoryLine."Entry No." := PostedStoreInventoryLine.RunEntryNo();
                PostedStoreInventoryLine."Journal ID" := pTransferJournalID;
                PostedStoreInventoryLine.Insert();
            until StoreInventoryLine.Next() = 0;
        end;

        //StoreInventoryLine.Reset();
        //StoreInventoryLine.SetRange(WorksheetSeqNo,pWorksheetSeqNo);
        //StoreInventoryLine.DeleteAll();
        Commit();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunPurchPost(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    procedure GetDocInsLog(pDocumentNo: Code[20]; pFunctionsName: Text)
    begin
        //--A-- 2023/05/17
        DocumentNo := pDocumentNo;
        FunctionsName := pFunctionsName;
        //--A-- 2023/05/17
    end;

    local procedure "------------Call API Test------------"()
    begin
    end;


    procedure TestCallAPI(): Boolean
    var
        llStatus: Boolean;
        URLTest: Text;
    begin
        // For Test
        Clear(JsonRequestStr);
        Clear(APIResult);
        CheckConfigInterface();

        // postInventCountingJournal(str company,str warehouse,anytype journaldata)
        URLTest := 'https://bigcamera-uat.sandbox.operations.dynamics.com/';
        JsonRequestStr := StrSubstNo('{company:"%1",warehouse:"%2",item:"%3"}', Company_Name, '10822-A', '0000000199');

        /*
        // postTransferJournal(str company,str warehouse,anytype journaldata)
        URLTest := 'https://com7-devaos.sandbox.ax.dynamics.com/api/services/BPC_InterfaceServiceGroup/BPC_InventJournalService/getOnHandInventoryByWarehouse';
        JsonRequestStr := StrSubstNo('{company:"%1",warehouse:"%2",item:"%3"}',Company_Name,'10822-A','0000000199');
        */
        FunctionsName := 'TestCallAPI';
        if CallAPIService_POST(URLTest, JsonRequestStr, APIResult, DocumentNo) then
            Message('Complete.')
        else
            ERROR('%1', GETLASTERRORTEXT);

    end;

    local procedure "------------ Loop Test ------------"()
    begin
    end;


    procedure LoopSendItem(ItemFilter: Text)
    var
        Item: Record Item;
        LocWindow: Dialog;
    begin
        LocWindow.OPEN('Send Item  #1#############');
        Item.Reset();
        Item.SETFILTER("No.", ItemFilter);
        if Item.FindSet() then
            repeat
                LocWindow.Update(1, Item."No.");
                PostItemToFO(Item);
            until Item.Next() = 0;
        LocWindow.Close();
        Message('Ok');
    end;

    procedure IsDepositUsed(pStore: Code[10]; pPOSTerminal: Code[10]; pTransactionNo: Integer): Boolean
    var
        Infocodes: Record "LSC Infocode";
        TransInfocodeEntry: Record "LSC Trans. Infocode Entry";
    begin
        Infocodes.Reset();
        Infocodes.SetRange(Type, Infocodes.Type::"Apply To Entry");
        Infocodes.SetRange("Data Entry Type", 'DEPOSIT');
        if Infocodes.FindSet() then begin
            TransInfocodeEntry.Reset();
            TransInfocodeEntry.SetRange("Store No.", pStore);
            TransInfocodeEntry.SetRange("POS Terminal No.", pPOSTerminal);
            TransInfocodeEntry.SetRange("Transaction No.", pTransactionNo);
            TransInfocodeEntry.SetRange(Infocode, Infocodes.Code);
            if TransInfocodeEntry.FindSet() then
                exit(true);
        end;
    end;

    procedure SkipReceiptVoidJournal(pStore: Code[10]; pPOSTerminalNo: Code[10]; pTransactionNo: Integer): Boolean
    var
        TransHeader: Record "LSC Transaction Header";
        TransVoid: Record "LSC Transaction Header";

    begin
        exit(false);

        // if TransHeader.Get(pStore, pPOSTerminalNo, pTransactionNo) then begin
        //     TransVoid.Reset();
        //     TransVoid.SetRange("Retrieved from Receipt No.", TransHeader."Receipt No.");
        //     TransVoid.SetRange(Date, TransHeader.Date);
        //     if TransVoid.FindSet() then
        //         //คืนของวันเดียวกัน false = ส่ง
        //         exit(false)
        //     else begin
        //         if (TransHeader."Retrieved from Receipt No." <> '') and (TransHeader."Sale Is Return Sale") then begin
        //             TransVoid.Reset();
        //             TransVoid.SetRange("Receipt No.", TransHeader."Retrieved from Receipt No.");
        //             TransVoid.SetRange(Date, TransHeader.Date);
        //             if TransVoid.FindSet() then
        //                 //คืนของคนละวันแต่ Retrieved from Receipt No. มีข้อมูล และ  Sale Is Return Sale เป็น true = ไม่ส่ง 
        //                 exit(true)
        //         end;
        //     end;
        // end;
    end;

    procedure SkipReceiptVoid(pStore: Code[10]; pPOSTerminalNo: Code[10]; pTransactionNo: Integer): Boolean
    var
        TransHeader: Record "LSC Transaction Header";
        TransVoid: Record "LSC Transaction Header";

    begin
        // if TransHeader.Get(pStore, pPOSTerminalNo, pTransactionNo) then begin
        //     TransVoid.Reset();
        //     TransVoid.SetRange("Retrieved from Receipt No.", TransHeader."Receipt No.");
        //     TransVoid.SetRange("Sale Is Return Sale", true);
        //     TransVoid.SetRange(Date, TransHeader.Date);
        //     if TransVoid.FindSet() and TransHeader."Sale Is Return Sale" then
        //         exit(true);
        // end;

        if TransHeader.Get(pStore, pPOSTerminalNo, pTransactionNo) then begin


            TransVoid.Reset();
            TransVoid.SetRange("Retrieved from Receipt No.", TransHeader."Receipt No.");
            // TransVoid.SetRange("Sale Is Return Sale", true);
            TransVoid.SetRange(Date, TransHeader.Date);
            TransVoid.SetFilter("Entry Status", '<>Voided');
            if TransVoid.FindSet() then
                //คืนของวันเดียวกัน = ไม่ส่ง
                exit(true)
            else begin
                if (TransHeader."Retrieved from Receipt No." <> '') and (TransHeader."Sale Is Return Sale") then begin
                    TransVoid.Reset();
                    TransVoid.SetRange("Receipt No.", TransHeader."Retrieved from Receipt No.");
                    TransVoid.SetFilter("Entry Status", '<>Voided');
                    TransVoid.SetRange(Date, TransHeader.Date);
                    if TransVoid.FindSet() then
                        //คืนของคนละวันแต่ Retrieved from Receipt No. มีข้อมูล และ  Sale Is Return Sale เป็น true = ไม่ส่ง 
                        exit(true)
                end;
            end;
        end;
    end;


    procedure CheckPostedStmtLine(PostedStmtNo: Code[20]; var pTmpPostedStmtLine: Record "LSC Posted Statement Line" temporary)
    var
        PostedStmtLine: Record "LSC Posted Statement Line";
        TransactionHeader: Record "LSC Transaction Header";
        TenderType: Text;
    begin
        pTmpPostedStmtLine.Reset();
        pTmpPostedStmtLine.DeleteAll();
        PostedStmtLine.Reset();
        PostedStmtLine.SetCurrentKey(PostedStmtLine."Tender Type");
        PostedStmtLine.SetRange("Statement No.", PostedStmtNo);
        PostedStmtLine.SETFILTER("Trans. Amount", '<>%1', 0);
        if PostedStmtLine.FindSet() then
            repeat
                if PostedStmtLine."Tender Type" <> TenderType then begin
                    TransactionHeader.Reset();
                    TransactionHeader.SetRange("Statement No.", PostedStmtNo);
                    TransactionHeader.SetRange("Transaction Type", TransactionHeader."Transaction Type"::Sales);
                    if TransactionHeader.FindSet() then
                        repeat
                            if not SkipReceiptVoidJournal(TransactionHeader."Store No.", TransactionHeader."POS Terminal No.", TransactionHeader."Transaction No.") then begin
                                pTmpPostedStmtLine.Reset();
                                pTmpPostedStmtLine.SetRange("Statement No.", PostedStmtLine."Statement No.");
                                pTmpPostedStmtLine.SetRange("Line No.", PostedStmtLine."Line No.");
                                if not pTmpPostedStmtLine.FindSet() then begin
                                    pTmpPostedStmtLine.Init();
                                    pTmpPostedStmtLine := PostedStmtLine;
                                    pTmpPostedStmtLine.Insert();
                                end;
                            end;
                        until TransactionHeader.Next() = 0;
                end;
                TenderType := PostedStmtLine."Tender Type";
            until PostedStmtLine.Next() = 0;

    end;

    procedure SkipReceiptVoidStmtMovement(pStore: Code[10]; pPOSTerminalNo: Code[10]; pTransactionNo: Integer): Boolean
    var
        TransHeader: Record "LSC Transaction Header";
        TransVoid: Record "LSC Transaction Header";

    begin
        if TransHeader.Get(pStore, pPOSTerminalNo, pTransactionNo) then begin
            TransVoid.Reset();
            TransVoid.SetRange("Retrieved from Receipt No.", TransHeader."Receipt No.");
            // TransVoid.SetRange("Sale Is Return Sale", true);
            TransVoid.SetRange(Date, TransHeader.Date);
            if TransVoid.FindSet() then
                exit(true)
            else begin
                if (TransHeader."Retrieved from Receipt No." <> '') and (TransHeader."Sale Is Return Sale") then begin
                    TransVoid.Reset();
                    TransVoid.SetRange("Receipt No.", TransHeader."Retrieved from Receipt No.");
                    TransVoid.SetRange(Date, TransHeader.Date);
                    if TransVoid.FindSet() then
                        exit(true)
                end;
            end;
        end;
    end;

    local procedure CalcTransAmt(PostedStmtNo: Code[20]; TenderType: Code[10]): Decimal
    var
        TransPaymentEntry: Record "LSC Trans. Payment Entry";
        TransactionHeader: Record "LSC Transaction Header";
        TransAmt: Decimal;
    begin
        Clear(TransAmt);
        TransactionHeader.Reset();
        TransactionHeader.SetRange("Statement No.", PostedStmtNo);
        TransactionHeader.SetRange("Transaction Type", TransactionHeader."Transaction Type"::Sales);
        if TransactionHeader.FindSet() then
            repeat
                if not SkipReceiptVoidJournal(TransactionHeader."Store No.", TransactionHeader."POS Terminal No.", TransactionHeader."Transaction No.") then begin
                    TransPaymentEntry.Reset();
                    TransPaymentEntry.SetRange("Store No.", TransactionHeader."Store No.");
                    TransPaymentEntry.SetRange("POS Terminal No.", TransactionHeader."POS Terminal No.");
                    TransPaymentEntry.SetRange("Transaction No.", TransactionHeader."Transaction No.");
                    TransPaymentEntry.SetRange("Tender Type", TenderType);
                    if TransPaymentEntry.FindSet() then begin
                        TransPaymentEntry.CalcSums("Amount Tendered");
                        if TransPaymentEntry."Amount Tendered" <> 0 then
                            TransAmt += TransPaymentEntry."Amount Tendered";
                    end;
                end;
            until TransactionHeader.Next() = 0;

        exit(TransAmt);
    end;


    procedure GetNetAmtAndVatAmt(pStore: Code[10];
            pPOSTerminal: Code[10];
            pTransaction: Integer; var
                                       pNetAmt: Decimal;

    var
        pVatAmt: Decimal)
    var
        TransalesEntry: Record "LSC Trans. Sales Entry";
    begin
        Clear(pNetAmt);
        Clear(pVatAmt);
        TransalesEntry.Reset();
        TransalesEntry.SetRange("Store No.", pStore);
        TransalesEntry.SetRange("POS Terminal No.", pPOSTerminal);
        TransalesEntry.SetRange("Transaction No.", pTransaction);
        if TransalesEntry.FindSet() then begin
            TransalesEntry.CalcSums("Net Amount", "VAT Amount");
            pNetAmt := TransalesEntry."Net Amount";
            pVatAmt := TransalesEntry."VAT Amount";
        end;
    end;

    procedure ItemExist(JsonText: Text; var ItemsNotExist: Text) ItemExist: Boolean
    var
        Item: Record Item;
        ItemNo: Text;
        ItemList: List of [Text];
    begin
        ItemExist := true;
        JArrayData.ReadFrom(JsonText);
        foreach JToken in JArrayData do begin
            JObjectData := JToken.AsObject();
            if JObjectData.Get('ItemNumber', JToken) then begin
                ItemNo := JToken.AsValue().AsText();
                if not Item.Get(ItemNo) then begin
                    ItemExist := false;
                    if not ItemList.Contains(ItemNo) then begin
                        ItemList.Add(ItemNo);
                        if ItemsNotExist <> '' then
                            ItemsNotExist += ', ';
                        ItemsNotExist += ItemNo;
                    end;
                end;
            end;
        end;
    end;

    procedure ValidPostedStatementSalesQty(PostedStatement: Record "LSC Posted Statement"; ShowMessage: Boolean): Boolean
    var
        TransactionHdr: Record "LSC Transaction Header";
        ItemLedgerEnt: Record "Item Ledger Entry";
        TransSalesEnt: Record "LSC Trans. Sales Entry";
        MovementQty: Decimal;
        JournalQty: Decimal;
    begin
        MovementQty := 0;
        JournalQty := 0;

        TransactionHdr.SetRange("Posted Statement No.", PostedStatement."No.");
        TransactionHdr.SetRange("Transaction Type", TransactionHdr."Transaction Type"::Sales);
        if TransactionHdr.FindSet() then
            repeat
                ItemLedgerEnt.Reset();
                ItemLedgerEnt.SetRange("Document No.", StrSubstNo('%1-%2-%3', TransactionHdr."Store No.", TransactionHdr."POS Terminal No.", TransactionHdr."Transaction No."));
                ItemLedgerEnt.SetRange("Entry Type", "Item Ledger Entry Type"::Sale);
                if ItemLedgerEnt.FindSet() then begin
                    ItemLedgerEnt.CalcSums(Quantity);
                    MovementQty += ItemLedgerEnt.Quantity;
                end;

                TransSalesEnt.Reset();
                TransSalesEnt.SetRange("Store No.", TransactionHdr."Store No.");
                TransSalesEnt.SetRange("POS Terminal No.", TransactionHdr."POS Terminal No.");
                TransSalesEnt.SetRange("Transaction No.", TransactionHdr."Transaction No.");
                if TransSalesEnt.FindSet() then begin
                    TransSalesEnt.CalcSums(Quantity);
                    JournalQty += TransSalesEnt.Quantity;
                end;

            until TransactionHdr.Next() = 0;

        if ShowMessage then
            Message('Statement No.: %1\Movement Qty: %2\Journal Qty:%3', PostedStatement."No.", Abs(MovementQty), Abs(JournalQty));

        exit(MovementQty = JournalQty);
    end;

    //Oat Mark Posted to FO useless  ++
    // procedure MarkSentToFO(DocNo: Text; DocType: Option Shipment,Receipt)
    // var
    //     TransferShipmentHeader: record "Transfer Shipment Header";
    //     TransferReceiptHeader: record "Transfer Receipt Header";
    // begin
    //     // if Status = false then
    //     //     exit;
    //     // if DocNo = '' then
    //     //     exit;
    //     case DocType of
    //         DocType::Shipment:
    //             begin
    //                 if TransferShipmentHeader.Get(DocNo) then
    //                     TransferShipmentHeader.ModifyAll("BPC Send To FO", true);
    //             end;
    //         DocType::Receipt:
    //             begin
    //                 if TransferReceiptHeader.Get(DocNo) then
    //                     TransferReceiptHeader.ModifyAll("BPC Send To FO", true);
    //             end;
    //     end;
    // end;
    //Oat Mark Posted to FO  --

    // trigger JObjectData::PropertyChanged(sender: Variant; e: DotNet PropertyChangedEventArgs)
    // begin
    // end;

    // trigger JObjectData::PropertyChanging(sender: Variant; e: DotNet PropertyChangingEventArgs)
    // begin
    // end;

    // trigger JObjectData::ListChanged(sender: Variant; e: DotNet ListChangedEventArgs)
    // begin
    // end;

    // trigger JObjectData::AddingNew(sender: Variant; e: DotNet AddingNewEventArgs)
    // begin
    // end;

    // trigger JObjectData::CollectionChanged(sender: Variant; e: DotNet NotifyCollectionChangedEventArgs)
    // begin
    // end;

    // trigger JArrayData::ListChanged(sender: Variant; e: DotNet ListChangedEventArgs)
    // begin
    // end;

    // trigger JArrayData::AddingNew(sender: Variant; e: DotNet AddingNewEventArgs)
    // begin
    // end;

    // trigger JArrayData::CollectionChanged(sender: Variant; e: DotNet NotifyCollectionChangedEventArgs)
    // begin
    // end;
}

