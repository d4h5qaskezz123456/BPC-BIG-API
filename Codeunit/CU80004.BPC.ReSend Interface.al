codeunit 80004 "BPC.ReSend Interface"
{
    Permissions = tabledata 110 = rim;
    trigger OnRun()
    var

    begin
        // RunJobPostTransfersShipment();
        // RunJobPostTransfersReceipt();
    end;

    local procedure RunJobPostTransfersShipment()
    var
        InterfaceData: Codeunit "BPC.Interface Data";
        ErrText: Text;
        Location: Record Location;
        TransferShipmentHeader: record "Transfer Shipment Header";
        TransHeader: Record "Transfer Header";
        RetailSetup: Record "LSC Retail Setup";
    begin

        // TransferShipmentHeader.Reset();
        // TransferShipmentHeader.SetRange("Transfer-from Code", 'HA002');
        // if TransferShipmentHeader.FindSet() then begin
        //     TransferShipmentHeader.ModifyAll("BPC Send To FO", false);
        // end;

        RetailSetup.Get();
        TransferShipmentHeader.Reset();
        TransferShipmentHeader.SetRange("BPC Send To FO", false);
        if TransferShipmentHeader.FindSet() then begin
            repeat
                if not Location.Get(TransferShipmentHeader."Transfer-from Code") then
                    Location.Init();
                IF (RetailSetup."BPC.Interface D365 Active") and (not Location."BPC.Not sent to FO") THEN begin
                    ReSendPostTransfersShipment(TransferShipmentHeader);
                    TransferShipmentHeader."BPC Send To FO" := true;
                    TransferShipmentHeader.Modify();
                end;
            until TransferShipmentHeader.Next() = 0
        end;
    end;

    local procedure RunJobPostTransfersReceipt()
    var
        InterfaceData: Codeunit "BPC.Interface Data";
        ErrText: Text;
        Location: Record Location;
        TransferReceiptHeader: record "Transfer Receipt Header";
        TransHeader: Record "Transfer Header";
        RetailSetup: Record "LSC Retail Setup";
    begin

        // TransferReceiptHeader.Reset();
        // TransferReceiptHeader.SetRange("Transfer-from Code", 'HA002');
        // if TransferReceiptHeader.FindSet() then begin
        //     TransferReceiptHeader.ModifyAll("BPC Send To FO", false);
        // end;

        RetailSetup.Get();
        TransferReceiptHeader.Reset();
        TransferReceiptHeader.SetRange("BPC Send To FO", false);
        if TransferReceiptHeader.FindSet() then begin
            repeat
                if not Location.Get(TransferReceiptHeader."Transfer-from Code") then
                    Location.Init();
                IF (RetailSetup."BPC.Interface D365 Active") and (not Location."BPC.Not sent to FO") THEN begin
                    ReSendPostTransfersReceipt(TransferReceiptHeader, false, ErrText);
                    TransferReceiptHeader."BPC Send To FO" := true;
                    TransferReceiptHeader.Modify();
                end;
            until TransferReceiptHeader.Next() = 0
        end;
    end;

    procedure ReSendSendPurchaseReceive(var Rec: Record "Purch. Rcpt. Header"): Boolean
    var
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
        CLEAR(JsonRequestStr);
        CLEAR(APIResult);
        CLEAR(RecRef);
        CLEAR(ErrorMsg);
        RetailSetup.Get();
        Company_Name := RetailSetup."BPC.Interface Company";
        InterfaceData.CheckConfigInterface();
        //DRPH
        IF NOT InterfaceDocumentStatus.GET(InterfaceDocumentStatus."BPC.Document Type"::GRN, Rec."No.") THEN BEGIN
            InterfaceDocumentStatus.INIT;
            InterfaceDocumentStatus."BPC.Document Type" := InterfaceDocumentStatus."BPC.Document Type"::GRN;
            InterfaceDocumentStatus."BPC.Document No." := Rec."No.";
            InterfaceDocumentStatus.INSERT;
        END;
        InterfaceDocumentStatus."BPC.Interface Date-Time" := CURRENTDATETIME;
        InterfaceDocumentStatus."BPC.Posted At FO" := FALSE;
        InterfaceDocumentStatus."BPC.Reference Document No." := PurchRcptHeader."Order No.";
        InterfaceDocumentStatus.MODIFY;
        //DRPH
        FunctionsName := 'SendPurchaseReceive';
        DocumentNo := Rec."Order No.";
        JsonRequestStr := Convert.ToBase64(CreateJsonRequestStr(FunctionsName, Rec."No."));
        JsonRequestStr := STRSUBSTNO('{company:"%1",warehouse:"%2",PoReceipt:"%3"}', Company_Name, Rec."Location Code", JsonRequestStr);
        IF InterfaceData.CallAPIService_POST(FunctionsName, JsonRequestStr, APIResult, DocumentNo) THEN BEGIN
            CLEAR(JSONMgt);
            JArrayData.ReadFrom(APIResult);
            FOREACH JToken IN JArrayData DO BEGIN
                JObjectData := JToken.AsObject();
                if JObjectData.get('Status', JToken) then
                    llStatus := JToken.AsValue().AsBoolean();
                if JObjectData.get('PONo', JToken) then
                    lcPONo := JToken.AsValue().AsText();
                if JObjectData.get('GRNNo', JToken) then
                    lcGRNNo := JToken.AsValue().AsText();
                if JObjectData.get('Message', JToken) then
                    ErrorMsg := JToken.AsValue().AsText();
                IF (NOT llStatus) OR (lcGRNNo = '') THEN BEGIN
                    IF ErrorMsg <> '' THEN
                        MESSAGE(Text001, ErrorMsg)
                    ELSE
                        MESSAGE('Send GRN to FO.\API: %1', APIResult);
                    EXIT(FALSE);
                END;
                MESSAGE('PO No. %1 has been Receive.', lcPONo);
                EXIT(TRUE);
            END;
        END ELSE BEGIN
            MESSAGE('%1', GETLASTERRORTEXT);
            EXIT(FALSE);
        END;
    end;

    procedure ReSendPostSalesShipment(var Rec: Record "Sales Shipment Header"): Boolean
    var
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
    begin
        CLEAR(JsonRequestStr);
        CLEAR(APIResult);
        CLEAR(RecRef);
        CLEAR(ErrorMsg);
        RetailSetup.Get();
        Company_Name := RetailSetup."BPC.Interface Company";
        InterfaceData.CheckConfigInterface();
        RecRef.GETTABLE(Rec);
        FunctionsName := 'PostSalesShipment';
        DocumentNo := Rec."Order No.";
        JsonRequestStr := Convert.ToBase64(CreateJsonRequestStr(FunctionsName, Rec."No."));
        //Error(JsonRequestStr);
        JsonRequestStr := STRSUBSTNO('{company:"%1",warehouse:"%2",data:"%3"}', Company_Name, Rec."Location Code", JsonRequestStr);
        IF InterfaceData.CallAPIService_POST(FunctionsName, JsonRequestStr, APIResult, DocumentNo) THEN BEGIN
            CLEAR(JSONMgt);
            JArrayData.ReadFrom(APIResult);
            FOREACH JToken IN JArrayData DO BEGIN
                JObjectData := JToken.AsObject();
                if JObjectData.get('Status', JToken) then
                    llStatus := JToken.AsValue().AsBoolean();
                if JObjectData.get('SOH_SONo', JToken) then
                    lcOrderNo := JToken.AsValue().AsText();
                if JObjectData.get('SOH_CustShipNo', JToken) then
                    lcShipNO := JToken.AsValue().AsText();
                if JObjectData.get('Message', JToken) then
                    ErrorMsg := JToken.AsValue().AsText();
                if JObjectData.get('SOH_InvoicePDF', JToken) then begin
                    if JToken.AsValue().IsNull() then
                        Message('No PDF file information')
                    else
                        InvoicePDF := JToken.AsValue().AsText();
                end;

                IF NOT llStatus THEN BEGIN
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

                    IF ErrorMsg <> '' THEN
                        MESSAGE(Text001, ErrorMsg)
                    ELSE
                        MESSAGE('Can Not Post Ship.');

                    EXIT;
                END;

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
                MESSAGE('SO No. %1 has been Shipping.', lcOrderNo);
                EXIT(TRUE); //Success
            END;
        END ELSE BEGIN
            MESSAGE('%1', GETLASTERRORTEXT);
        END;
    end;

    procedure ReSendPostTransfersShipment(var Rec: Record "Transfer Shipment Header")
    var
        TransferPostShipment: Codeunit "TransferOrder-Post Shipment";
        TransHeader: Record "Transfer Header";
        llStatus: Boolean;
        lcOrderNo: Text;
        lcShipmentNo: Text;
        PostStatus: Boolean;
        InterfaceDATA: Codeunit "BPC.Interface Data";
        DocType: Option Shipment,Receipt;
    begin
        CLEAR(JsonRequestStr);
        CLEAR(APIResult);
        CLEAR(ErrorMsg);
        RetailSetup.Get();
        Company_Name := RetailSetup."BPC.Interface Company";
        InterfaceData.CheckConfigInterface();
        FunctionsName := 'PostTransfersShipment';
        DocumentNo := Rec."Transfer Order No.";
        JsonRequestStr := Convert.ToBase64(CreateJsonRequestStr(FunctionsName, Rec."No."));
        JsonRequestStr := STRSUBSTNO('{company:"%1",warehouse:"%2",shipment:"%3"}', Company_Name, Rec."Transfer-from Code", JsonRequestStr);
        IF InterfaceData.CallAPIService_POST(FunctionsName, JsonRequestStr, APIResult, DocumentNo) THEN BEGIN
            JArrayData.ReadFrom(APIResult);
            FOREACH JToken IN JArrayData DO BEGIN
                JObjectData := JToken.AsObject();
                if JObjectData.get('Status', JToken) then
                    llStatus := JToken.AsValue().AsBoolean();
                if JObjectData.get('TransferOrderNo', JToken) then
                    lcOrderNo := JToken.AsValue().AsText();
                if JObjectData.get('ShipmentNo', JToken) then
                    lcShipmentNo := JToken.AsValue().AsText();
                if JObjectData.get('Message', JToken) then
                    ErrorMsg := JToken.AsValue().AsText();
                IF NOT llStatus THEN BEGIN
                    IF ErrorMsg <> '' THEN
                        MESSAGE(Text001, ErrorMsg)
                    ELSE
                        MESSAGE('Can Not Post Ship.');
                    EXIT;
                END;
            END;
            MESSAGE('Transfer No. %1 has been Post Shipment.', lcOrderNo);
        END ELSE
            MESSAGE('%1', GETLASTERRORTEXT);
    END;

    procedure ReSendPostTransfersReceipt(var Rec: Record "Transfer Receipt Header"; HideDialog: Boolean; ErrText: Text)
    var
        lcOrderNo: Text;
        lcReceiptNo: Text;
        TransferReceiptHeader: Record "Transfer Receipt Header";
        llStatus: Boolean;
        InterfaceDATA: Codeunit "BPC.Interface Data";
        DocType: Option Shipment,Receipt;
    begin
        CLEAR(JsonRequestStr);
        CLEAR(APIResult);
        CLEAR(RecRef);
        CLEAR(ErrorMsg);
        RetailSetup.Get();
        Company_Name := RetailSetup."BPC.Interface Company";
        InterfaceData.CheckConfigInterface();
        FunctionsName := 'PostTransfersReceipt';
        DocumentNo := Rec."Transfer Order No.";
        JsonRequestStr := Convert.ToBase64(CreateJsonRequestStr(FunctionsName, Rec."No."));
        JsonRequestStr := STRSUBSTNO('{company:"%1",warehouse:"%2",receipt:"%3"}', Company_Name, Rec."Transfer-from Code", JsonRequestStr);
        IF InterfaceData.CallAPIService_POST(FunctionsName, JsonRequestStr, APIResult, DocumentNo) THEN BEGIN
            JArrayData.ReadFrom(APIResult);
            FOREACH JToken IN JArrayData DO BEGIN
                JObjectData := JToken.AsObject();
                if JObjectData.get('Status', JToken) then
                    llStatus := JToken.AsValue().AsBoolean();
                if JObjectData.get('TransferOrderNo', JToken) then
                    lcOrderNo := JToken.AsValue().AsText();
                if JObjectData.get('ReceiptNo', JToken) then
                    lcReceiptNo := JToken.AsValue().AsText();
                if JObjectData.get('Message', JToken) then
                    ErrorMsg := JToken.AsValue().AsText();
                IF NOT llStatus THEN BEGIN
                    IF ErrorMsg <> '' THEN
                        MESSAGE(Text001, ErrorMsg)
                    ELSE
                        MESSAGE('Can Not Post Receipt.');
                    EXIT;
                END;
            END;
            MESSAGE('Transfer No. %1 has been Post Receipt.', lcReceiptNo);
        END ELSE BEGIN
            MESSAGE('%1', GETLASTERRORTEXT);
        END;
    end;

    procedure CreateJsonRequestStr(SelectionFunctions: Text; No: Code[20]): Text
    var
        TransferShipmentHeader: Record "Transfer Shipment Header";
        TransferShipmentLine: Record "Transfer Shipment Line";
        TrackingSpecification: Record "Tracking Specification";
        TransferReceiptHeader: Record "Transfer Receipt Header";
        TransferReceiptLine: Record "Transfer Receipt Line";
        TMPItemLedgEntry: Record "BPC.TMPItemLedgEntry";
        JsonUtil: Codeunit "LSC POS JSON Util";
        ItemVariantRegistration: Record "LSC Item Variant Registration";
        ItemLedEnt: Record "Item Ledger Entry";
        Item: Record Item;
        ItemTracking: Record "Item Tracking Code";
        SalesShipmentHeader: Record "Sales Shipment Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        SalesShipmentLine: Record "Sales Shipment Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchHeader: Record "Purchase Header";
        ItemLedgEntry: Record "Item Ledger Entry";
        AssembletoOrderLink: Record "Assemble-to-Order Link";
        ReservationEntry: Record "Reservation Entry";
        PostedAssemblyLine: Record "Posted Assembly Line";
        ItemLedgerEntrySerial: Record "Item Ledger Entry";
        ItemEntryRelation: Record "Item Entry Relation";
        Skip: Boolean;
        CheckDocShipmentLine: text;
        ShipmentLine: Integer;
    begin
        CLEAR(JsonUtil);
        CASE SelectionFunctions OF
            'SendPurchaseReceive':
                BEGIN
                    PurchRcptHeader.RESET;
                    PurchRcptHeader.SETFILTER("No.", NO);
                    IF PurchRcptHeader.FINDSET THEN BEGIN
                        PurchHeader.GET(PurchHeader."Document Type"::Order, PurchRcptHeader."Order No.");
                        JsonUtil.StartJSon;
                        // Header
                        JsonUtil.AddToJSon('PurchH_PONo', PurchRcptHeader."Order No.");
                        JsonUtil.AddToJSon('PurchH_GRNNo', PurchRcptHeader."No.");
                        JsonUtil.AddToJSon('PurchH_VendShipNo', PurchRcptHeader."Vendor Shipment No.");
                        JsonUtil.AddToJSon('PurchH_BuyfromVendNo', PurchRcptHeader."Buy-from Vendor No.");
                        JsonUtil.AddToJSon('PurchH_VendInvNo', PurchHeader."Vendor Invoice No.");
                        JsonUtil.AddToJSon('PurchH_PostingDate', Format(PurchRcptHeader."Posting Date", 0, '<Year4>-<Month,2>-<Day,2>'));
                        JsonUtil.AddToJSon('PurchH_DocumentDate', Format(PurchRcptHeader."Document Date", 0, '<Year4>-<Month,2>-<Day,2>'));
                        // Line
                        PurchRcptLine.RESET;
                        PurchRcptLine.SETRANGE("Document No.", PurchRcptHeader."No.");
                        PurchRcptLine.SETFILTER(Quantity, '<>%1', 0);
                        IF PurchRcptLine.FINDSET THEN BEGIN
                            JsonUtil.StartJSonArray('PurchL');
                            REPEAT
                                IF NOT Item.GET(PurchRcptLine."No.") THEN
                                    Item.INIT;
                                IF NOT ItemTracking.GET(Item."Item Tracking Code") THEN
                                    ItemTracking.INIT;
                                JsonUtil.StartJSon;
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
                                IF ItemTracking."SN Specific Tracking" THEN BEGIN
                                    ItemLedgEntry.RESET;
                                    ItemLedgEntry.SETRANGE("Document Type", ItemLedgEntry."Document Type"::"Purchase Receipt");
                                    ItemLedgEntry.SETRANGE("Document No.", PurchRcptLine."Document No.");
                                    ItemLedgEntry.SETRANGE("Document Line No.", PurchRcptLine."Line No.");
                                    ItemLedgEntry.SETFILTER("Serial No.", '<>%1', '');
                                    IF ItemLedgEntry.FINDFIRST THEN BEGIN
                                        JsonUtil.StartJSonArray('Serial');
                                        REPEAT
                                            JsonUtil.StartJSon;
                                            JsonUtil.AddToJSon('Serial_ItemNo', ItemLedgEntry."Item No.");
                                            JsonUtil.AddToJSon('Serial_No', ItemLedgEntry."Serial No.");
                                            JsonUtil.AddToJSon('Serial_Qty', ItemLedgEntry.Quantity);
                                            JsonUtil.EndJSon;
                                        UNTIL ItemLedgEntry.NEXT = 0;
                                        JsonUtil.EndJSonArray;
                                    END;
                                END;
                                // Serial --
                                // Batch/Lot ++
                                IF (ItemTracking."Lot Specific Tracking") AND (ItemTracking."BPC.Lot Default to ERP" = '') THEN BEGIN
                                    ItemLedgEntry.RESET;
                                    ItemLedgEntry.SETRANGE("Document Type", ItemLedgEntry."Document Type"::"Purchase Receipt");
                                    ItemLedgEntry.SETRANGE("Document No.", PurchRcptLine."Document No.");
                                    ItemLedgEntry.SETRANGE("Document Line No.", PurchRcptLine."Line No.");
                                    ItemLedgEntry.SETFILTER("Lot No.", '<>%1', '');
                                    IF ItemLedgEntry.FINDFIRST THEN BEGIN
                                        JsonUtil.StartJSonArray('Batch');
                                        REPEAT
                                            JsonUtil.StartJSon;
                                            JsonUtil.AddToJSon('Batch_ItemNo', ItemLedgEntry."Item No.");
                                            JsonUtil.AddToJSon('Batch_No', ItemLedgEntry."Lot No.");
                                            JsonUtil.AddToJSon('Batch_Qty', ItemLedgEntry.Quantity);
                                            JsonUtil.AddToJSon('Batch_ExpireDate', FORMAT(ItemLedgEntry."Expiration Date", 0, '<Year4>-<Month,2>-<Day,2>'));
                                            JsonUtil.EndJSon;
                                        UNTIL ItemLedgEntry.NEXT = 0;
                                        JsonUtil.EndJSonArray;
                                    END;
                                END ELSE
                                    IF ItemTracking."BPC.Lot Default to ERP" <> '' THEN BEGIN
                                        JsonUtil.StartJSonArray('Batch');
                                        JsonUtil.StartJSon;
                                        JsonUtil.AddToJSon('Batch_ItemNo', PurchRcptLine."No.");
                                        JsonUtil.AddToJSon('Batch_No', ItemTracking."BPC.Lot Default to ERP");
                                        JsonUtil.AddToJSon('Batch_Qty', PurchRcptLine."Quantity (Base)");
                                        JsonUtil.EndJSon;
                                        JsonUtil.EndJSonArray;
                                    END;
                                // Batch/Lot ++
                                JsonUtil.EndJSon;
                            UNTIL PurchRcptLine.NEXT = 0;
                            JsonUtil.EndJSonArray;
                        END;
                        JsonUtil.EndJSon;
                    END;
                END;
            'PostTransfersShipment':
                BEGIN
                    TransferShipmentHeader.Reset();
                    TransferShipmentHeader.SetRange(TransferShipmentHeader."No.", No);
                    IF TransferShipmentHeader.FINDSET THEN BEGIN
                        JsonUtil.StartJSon;
                        // Header
                        JsonUtil.AddToJSon('Transf_No', TransferShipmentHeader."Transfer Order No.");//oat
                        JsonUtil.AddToJSon('Transf_Storefrom', TransferShipmentHeader."LSC Store-from");
                        JsonUtil.AddToJSon('Transf_Transffrom', TransferShipmentHeader."Transfer-from Code");
                        JsonUtil.AddToJSon('Transf_Storeto', TransferShipmentHeader."LSC Store-to");
                        JsonUtil.AddToJSon('Transf_Transfto', TransferShipmentHeader."Transfer-to Code");
                        JsonUtil.AddToJSon('Transf_PostingDate', FORMAT(TransferShipmentHeader."Posting Date", 0, '<Year4>-<Month,2>-<Day,2>'));
                        // Line
                        TransferShipmentLine.Reset();
                        TransferShipmentLine.SetRange("Document No.", TransferShipmentHeader."No.");
                        TransferShipmentLine.SETFILTER(Quantity, '<>0');
                        if TransferShipmentLine.FindSet() then begin
                            JsonUtil.StartJSonArray('TransfL');
                            REPEAT
                                JsonUtil.StartJSon;
                                JsonUtil.AddToJSon('TransfL_DocNo', TransferShipmentLine."Document No.");
                                JsonUtil.AddToJSon('TransfL_LineNo', TransferShipmentLine."Line No.");
                                JsonUtil.AddToJSon('TransfL_ItemNo', TransferShipmentLine."Item No.");
                                JsonUtil.AddToJSon('TransfL_Location', '');
                                JsonUtil.AddToJSon('TransfL_Qty', TransferShipmentLine."Quantity (Base)");
                                JsonUtil.AddToJSon('TransfL_UM', TransferShipmentLine."Unit of Measure Code");
                                Item.GET(TransferShipmentLine."Item No.");
                                IF NOT ItemTracking.GET(Item."Item Tracking Code") THEN
                                    ItemTracking.INIT;
                                ItemVariantRegistration.RESET;
                                ItemVariantRegistration.SETFILTER("Item No.", '%1', TransferShipmentLine."Item No.");
                                ItemVariantRegistration.SETFILTER(Variant, '%1', TransferShipmentLine."Variant Code");
                                IF NOT ItemVariantRegistration.FINDSET THEN
                                    ItemVariantRegistration.INIT;
                                JsonUtil.AddToJSon('TransfL_Variant', ItemVariantRegistration."Variant Dimension 1");
                                // Serial
                                IF NOT ItemTracking.GET(Item."Item Tracking Code") THEN
                                    ItemTracking.INIT;

                                ItemEntryRelation.Reset();
                                ItemEntryRelation.SetRange("Source Type", Database::"Transfer Shipment Line");
                                ItemEntryRelation.SetRange("Source Subtype", 0);
                                ItemEntryRelation.SetRange("Source ID", TransferShipmentLine."Document No.");
                                ItemEntryRelation.SetRange("Source Ref. No.", TransferShipmentLine."Line No.");
                                if ItemEntryRelation.FindSet() then begin
                                    JsonUtil.StartJSonArray('Serial');
                                    repeat
                                        ItemLedEnt.reset;
                                        ItemLedEnt.SetRange("Entry No.", ItemEntryRelation."Item Entry No.");
                                        if ItemLedEnt.FindSet() then begin
                                            JsonUtil.StartJSon;
                                            JsonUtil.AddToJSon('Serial_ItemNo', ItemLedEnt."Item No.");
                                            JsonUtil.AddToJSon('Serial_No', ItemLedEnt."Serial No.");
                                            JsonUtil.AddToJSon('Serial_Qty', ABS(ItemLedEnt."Quantity"));
                                            JsonUtil.EndJSon;
                                        end;
                                    until ItemEntryRelation.Next() = 0;
                                    // JsonUtil.EndJSonArray;
                                    // JsonUtil.StartJSonArray('Batch');
                                    // JsonUtil.StartJSon;
                                    // JsonUtil.AddToJSon('Batch_ItemNo', '');
                                    // JsonUtil.AddToJSon('Batch_No', '');
                                    // JsonUtil.AddToJSon('Batch_Qty', '');
                                    // JsonUtil.EndJSon;
                                    JsonUtil.EndJSonArray;
                                end else begin
                                    JsonUtil.StartJSonArray('Serial');
                                    JsonUtil.StartJSon;
                                    JsonUtil.AddToJSon('Serial_ItemNo', '');
                                    JsonUtil.AddToJSon('Serial_No', '');
                                    JsonUtil.AddToJSon('Serial_Qty', '');
                                    JsonUtil.EndJSon;
                                    JsonUtil.EndJSonArray;

                                    // JsonUtil.StartJSonArray('Batch');
                                    // JsonUtil.StartJSon;
                                    // JsonUtil.AddToJSon('Batch_ItemNo', '');
                                    // JsonUtil.AddToJSon('Batch_No', '');
                                    // JsonUtil.AddToJSon('Batch_Qty', '');
                                    // JsonUtil.EndJSon;
                                    // JsonUtil.EndJSonArray;
                                end;
                                // IF ItemTracking."SN Specific Tracking" THEN BEGIN
                                //     ItemLedEnt.reset;
                                //     ItemLedEnt.SetRange("Document No.", TransferShipmentLine."Document No.");
                                //     ItemLedEnt.SetRange("Document Line No.", TransferShipmentLine."Line No.");
                                //     ItemLedEnt.SetRange("Entry Type", ItemLedEnt."Entry Type"::Transfer);
                                //     if ItemLedEnt.FindSet() then begin
                                //         if ItemLedEnt."Serial No." <> '' then begin
                                //             JsonUtil.StartJSonArray('Serial');
                                //             JsonUtil.StartJSon;
                                //             JsonUtil.AddToJSon('Serial_ItemNo', ItemLedEnt."Item No.");
                                //             JsonUtil.AddToJSon('Serial_No', ItemLedEnt."Serial No.");
                                //             JsonUtil.AddToJSon('Serial_Qty', ABS(ItemLedEnt."Quantity"));
                                //             JsonUtil.EndJSon;
                                //             JsonUtil.EndJSonArray;
                                //         end else begin
                                //             JsonUtil.StartJSonArray('Serial');
                                //             JsonUtil.StartJSon;
                                //             JsonUtil.AddToJSon('Serial_ItemNo', '');
                                //             JsonUtil.AddToJSon('Serial_No', '');
                                //             JsonUtil.AddToJSon('Serial_Qty', '');
                                //             JsonUtil.EndJSon;
                                //             JsonUtil.EndJSonArray;
                                //         end;
                                //         if ItemLedEnt."Lot No." <> '' then begin
                                //             JsonUtil.StartJSonArray('Batch');
                                //             JsonUtil.StartJSon;
                                //             JsonUtil.AddToJSon('Batch_ItemNo', ItemLedEnt."Item No.");
                                //             JsonUtil.AddToJSon('Batch_No', ItemLedEnt."Lot No.");
                                //             JsonUtil.AddToJSon('Batch_Qty', ABS(ItemLedEnt."Quantity"));
                                //             JsonUtil.EndJSonArray;
                                //         end else begin
                                //             JsonUtil.StartJSonArray('Batch');
                                //             JsonUtil.StartJSon;
                                //             JsonUtil.AddToJSon('Batch_ItemNo', '');
                                //             JsonUtil.AddToJSon('Batch_No', '');
                                //             JsonUtil.AddToJSon('Batch_Qty', '');
                                //             JsonUtil.EndJSon;
                                //             JsonUtil.EndJSonArray;
                                //         end;
                                //     end;
                                // end;
                                JsonUtil.EndJSon;
                            UNTIL TransferShipmentLine.NEXT = 0;
                            JsonUtil.EndJSonArray;
                        END;
                        JsonUtil.EndJSon;
                    end;
                end;
            'PostTransfersReceipt':
                BEGIN
                    TransferReceiptHeader.RESET;
                    TransferReceiptHeader.SETRANGE("No.", NO);
                    IF TransferReceiptHeader.FINDSET THEN BEGIN
                        JsonUtil.StartJSon;
                        // Header
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
                            REPEAT
                                JsonUtil.StartJSon;
                                JsonUtil.AddToJSon('TransfL_DocNo', TransferReceiptLine."Document No.");
                                JsonUtil.AddToJSon('TransfL_LineNo', TransferReceiptLine."Line No.");
                                JsonUtil.AddToJSon('TransfL_ItemNo', TransferReceiptLine."Item No.");
                                JsonUtil.AddToJSon('TransfL_Location', '');
                                JsonUtil.AddToJSon('TransfL_Qty', TransferReceiptLine."Quantity (Base)");
                                JsonUtil.AddToJSon('TransfL_UM', TransferReceiptLine."Unit of Measure Code");
                                Item.GET(TransferReceiptLine."Item No.");
                                IF NOT ItemTracking.GET(Item."Item Tracking Code") THEN
                                    ItemTracking.INIT;
                                ItemVariantRegistration.RESET;
                                ItemVariantRegistration.SETFILTER("Item No.", '%1', TransferReceiptLine."Item No.");
                                ItemVariantRegistration.SETFILTER(Variant, '%1', TransferReceiptLine."Variant Code");
                                IF NOT ItemVariantRegistration.FINDSET THEN
                                    ItemVariantRegistration.INIT;
                                JsonUtil.AddToJSon('TransfL_Variant', ItemVariantRegistration."Variant Dimension 1");
                                // Serial
                                IF NOT ItemTracking.GET(Item."Item Tracking Code") THEN
                                    ItemTracking.INIT;
                                ItemEntryRelation.Reset();
                                ItemEntryRelation.SetRange("Source Type", Database::"Transfer Receipt Line");
                                ItemEntryRelation.SetRange("Source Subtype", 0);
                                ItemEntryRelation.SetRange("Source ID", TransferReceiptLine."Document No.");
                                ItemEntryRelation.SetRange("Source Ref. No.", TransferReceiptLine."Line No.");
                                if ItemEntryRelation.FindSet() then begin
                                    JsonUtil.StartJSonArray('Serial');
                                    repeat
                                        ItemLedEnt.reset;
                                        ItemLedEnt.SetRange("Entry No.", ItemEntryRelation."Item Entry No.");
                                        if ItemLedEnt.FindSet() then begin

                                            JsonUtil.StartJSon;
                                            JsonUtil.AddToJSon('Serial_ItemNo', ItemLedEnt."Item No.");
                                            JsonUtil.AddToJSon('Serial_No', ItemLedEnt."Serial No.");
                                            JsonUtil.AddToJSon('Serial_Qty', ABS(ItemLedEnt."Quantity"));
                                            JsonUtil.EndJSon;

                                            // JsonUtil.StartJSonArray('Batch');
                                            // JsonUtil.StartJSon;
                                            // JsonUtil.AddToJSon('Batch_ItemNo', '');
                                            // JsonUtil.AddToJSon('Batch_No', '');
                                            // JsonUtil.AddToJSon('Batch_Qty', '');
                                            // JsonUtil.EndJSon;
                                            // JsonUtil.EndJSonArray;
                                        end;

                                    until ItemEntryRelation.Next() = 0;
                                    JsonUtil.EndJSonArray;

                                end else begin
                                    JsonUtil.StartJSonArray('Serial');
                                    JsonUtil.StartJSon;
                                    JsonUtil.AddToJSon('Serial_ItemNo', '');
                                    JsonUtil.AddToJSon('Serial_No', '');
                                    JsonUtil.AddToJSon('Serial_Qty', '');
                                    JsonUtil.EndJSon;
                                    JsonUtil.EndJSonArray;

                                    // JsonUtil.StartJSonArray('Batch');
                                    // JsonUtil.StartJSon;
                                    // JsonUtil.AddToJSon('Batch_ItemNo', '');
                                    // JsonUtil.AddToJSon('Batch_No', '');
                                    // JsonUtil.AddToJSon('Batch_Qty', '');
                                    // JsonUtil.EndJSon;
                                    // JsonUtil.EndJSonArray;
                                end;
                                // IF ItemTracking."SN Specific Tracking" THEN BEGIN
                                //     ItemLedEnt.reset;
                                //     ItemLedEnt.SetRange("Document No.", TransferReceiptLine."Document No.");
                                //     ItemLedEnt.SetRange("Document Line No.", TransferReceiptLine."Line No.");
                                //     ItemLedEnt.SetRange("Entry Type", ItemLedEnt."Entry Type"::Transfer);
                                //     if ItemLedEnt.FindSet() then begin
                                //         if ItemLedEnt."Serial No." <> '' then begin
                                //             JsonUtil.StartJSonArray('Serial');
                                //             JsonUtil.StartJSon;
                                //             JsonUtil.AddToJSon('Serial_ItemNo', ItemLedEnt."Item No.");
                                //             JsonUtil.AddToJSon('Serial_No', ItemLedEnt."Serial No.");
                                //             JsonUtil.AddToJSon('Serial_Qty', ABS(ItemLedEnt."Quantity"));
                                //             JsonUtil.EndJSon;
                                //             JsonUtil.EndJSonArray;
                                //         end else begin
                                //             JsonUtil.StartJSonArray('Serial');
                                //             JsonUtil.StartJSon;
                                //             JsonUtil.AddToJSon('Serial_ItemNo', '');
                                //             JsonUtil.AddToJSon('Serial_No', '');
                                //             JsonUtil.AddToJSon('Serial_Qty', '');
                                //             JsonUtil.EndJSon;
                                //             JsonUtil.EndJSonArray;
                                //         end;
                                //         if ItemLedEnt."Lot No." <> '' then begin
                                //             JsonUtil.StartJSonArray('Batch');
                                //             JsonUtil.StartJSon;
                                //             JsonUtil.AddToJSon('Batch_ItemNo', ItemLedEnt."Item No.");
                                //             JsonUtil.AddToJSon('Batch_No', ItemLedEnt."Lot No.");
                                //             JsonUtil.AddToJSon('Batch_Qty', ABS(ItemLedEnt."Quantity"));
                                //             JsonUtil.EndJSonArray;
                                //         end else begin
                                //             JsonUtil.StartJSonArray('Batch');
                                //             JsonUtil.StartJSon;
                                //             JsonUtil.AddToJSon('Batch_ItemNo', '');
                                //             JsonUtil.AddToJSon('Batch_No', '');
                                //             JsonUtil.AddToJSon('Batch_Qty', '');
                                //             JsonUtil.EndJSon;
                                //             JsonUtil.EndJSonArray;
                                //         end;
                                //     end;
                                // end;
                                JsonUtil.EndJSon;
                            UNTIL TransferReceiptLine.NEXT = 0;
                            JsonUtil.EndJSonArray;
                        END;
                        JsonUtil.EndJSon;
                    end;
                END;
            'PostSalesShipment':
                BEGIN
                    SalesShipmentHeader.RESET;
                    SalesShipmentHeader.SetRange("No.", No);
                    IF SalesShipmentHeader.FINDSET THEN BEGIN
                        JsonUtil.StartJSon;
                        // Header
                        JsonUtil.AddToJSon('SOH_SONo', SalesShipmentHeader."Order No.");
                        JsonUtil.AddToJSon('SOH_CustShipNo', '');
                        JsonUtil.AddToJSon('SOH_SellToCustNo', SalesShipmentHeader."Sell-to Customer No.");
                        JsonUtil.AddToJSon('SOH_PostingDate', Format(SalesShipmentHeader."Posting Date", 0, '<Year4>-<Month,2>-<Day,2>'));
                        JsonUtil.AddToJSon('SOH_DocumentDate', Format(SalesShipmentHeader."Document Date", 0, '<Year4>-<Month,2>-<Day,2>'));
                        // Line
                        SalesShipmentLine.RESET;
                        SalesShipmentLine.SETRANGE("Document No.", SalesShipmentHeader."No.");
                        SalesShipmentLine.SETFILTER(Quantity, '<>%1', 0);
                        IF SalesShipmentLine.FINDSET THEN BEGIN
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
        EXIT(JsonUtil.GetJSon());
    END;

    local procedure CheckSerialItemLedger(ItemLedgerEntry: Record "Item Ledger Entry") CheckSerial: Boolean
    var
    begin
        TmpItemLedgerEntry.Reset();
        TmpItemLedgerEntry.SetRange("Item No.", ItemLedgerEntry."Item No.");
        TmpItemLedgerEntry.SetRange("Serial No.", ItemLedgerEntry."Serial No.");
        if not TmpItemLedgerEntry.FindSet() then begin
            TmpItemLedgerEntry.TransferFields(ItemLedgerEntry);
            TmpItemLedgerEntry.Insert();
            EXIT(false);
        end else begin
            EXIT(true);
        end;
    end;

    var
        ReleasePurchDoc: Codeunit "Release Purchase Document";
        ReleaseSaleshDoc:
                Codeunit "Release Sales Document";
        JSONMgt:
                Codeunit "JSON Management";
        JsonUtil:
                Codeunit "LSC POS JSON Util";
        EposCtrl:
                Codeunit "LSC POS Control Interface";
        BOUtils:
                Codeunit "LSC BO Utils";
        JObjectData:
                JsonObject;
        JArrayData:
                JsonArray;
        JToken:
                JsonToken;
        Convert:
                Codeunit "Base64 Convert";
        GLSetup:
                Record "General Ledger Setup";
        RetailSetup:
                Record "LSC Retail Setup";
        APIConfiguration:
                Record "BPC.API Configuration";
        StoreInventoryWorksheet:
                Record "LSC Store Inventory Worksheet";
        StoreInventoryLine:
                Record "LSC Store Inventory Line";
        PostedStoreInventoryLine:
                Record "BPC.Posted Store InventoryLine";
        Vend:
                Record Vendor;
        PurchSetup:
                Record "Purchases & Payables Setup";
        SaleshSetup:
                Record "Sales & Receivables Setup";
        Store:
                Record "LSC Store";
        ItemVariantRegistration:
                Record "LSC Item Variant Registration";
        RecRef:
                RecordRef;
        Window:
                Dialog;
        WindowUPDATE:
                Integer;
        JsonRequestStr:
                Text;
        APIResult:
                Text;
        Text000:
                Label 'Do you really want to undo the selected Receipt lines?\Receipt No. %1';
        ErrorMsg:
                Text;
        Text001:
                Label 'D365 Error Message : %1';
        FunctionsName:
                Text;
        DocumentNo:
                Text;
        Company_Name:
                Text;
        LastShipmentNo:
                Code[20];
        LastReceiptNo:
                Code[20];
        JnlDocID_g:
                Code[20];
        InterfaceData:
                Codeunit "BPC.Interface Data";
        TmpItemLedgerEntry:
                Record "Item Ledger Entry" temporary;

}