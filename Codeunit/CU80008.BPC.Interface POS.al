codeunit 80008 "BPC.Interface POS"
{
    Permissions = tabledata 110 = rim, tabledata 36 = rim;

    // // GetSalesHeader_POS //GetSalesHeader
    // // GetSalesLine
    // // PostSalesShipment_POS

    procedure GetSalesHeader_POS()
    var
        RetailUser: Record "LSC Retail User";
        StoreLocation: Record "LSC Store Location";
        SalesHeader: Record "Sales Header";
    begin
        CLEAR(JsonRequestStr);
        CLEAR(APIResult);
        RetailSetup.Get();
        Company_Name := RetailSetup."BPC.Interface Company";
        InterfaceData.CheckConfigInterface();
        IF RetailUser.GET(USERID) THEN BEGIN
            StoreLocation.RESET;
            StoreLocation.SETRANGE("Store No.", RetailUser."Store No.");
            IF StoreLocation.FINDSET THEN BEGIN
                REPEAT
                    IF StoreLocation."Location Code" <> '' THEN BEGIN // วนขอข้อมูลแต่ละ Location
                        FunctionsName := 'GetSalesHeader';
                        DocumentNo := '';
                        JsonRequestStr := STRSUBSTNO('{company:"%1",warehouse:"%2"}', Company_Name, StoreLocation."Location Code");
                        IF InterfaceData.CallAPIService_POST(FunctionsName, JsonRequestStr, APIResult, DocumentNo) THEN BEGIN
                            GenerateTempSalesOrder(TRUE, APIResult, SalesHeader, StoreLocation."Location Code");
                            InsertSalesOrderHeader(TRUE, RetailUser."Store No.", StoreLocation."Location Code", SalesHeader);
                        END;
                    END;
                UNTIL StoreLocation.NEXT = 0;
            END;
        END;
    end;

    procedure GetSalesLine(var SalesHeader: Record "Sales Header")
    var
    begin
        CLEAR(JsonRequestStr);
        CLEAR(APIResult);
        //InterfaceData.CheckConfigInterface();
        FunctionsName := 'GetSalesLine';
        DocumentNo := SalesHeader."No.";
        JsonRequestStr := STRSUBSTNO('{company:"%1",warehouse:"%2",salesOrder:"%3"}', Company_Name, SalesHeader."Location Code", SalesHeader."No.");
        IF InterfaceData.CallAPIService_POST(FunctionsName, JsonRequestStr, APIResult, DocumentNo) THEN BEGIN
            GenerateTempSalesOrder(FALSE, APIResult, SalesHeader, SalesHeader."Location Code");
            IF NOT InterfaceData.CheckExistPostedPending(SalesHeader."No.") THEN BEGIN
                //ReleaseSaleshDoc.PerformManualReopen(SalesHeader);
                InsertSalesOrderLine(SalesHeader)
                // if SalesHeader.Status = SalesHeader.Status::Open then
                //     ReleaseSaleshDoc.PerformManualRelease(SalesHeader);
            END;
        END ELSE
            MESSAGE('%1', GETLASTERRORTEXT);
    end;

    procedure PostSalesShipment_POS(var Rec: Record "LSC Transaction Header"): Boolean
    var
        SalesHeader: Record "Sales Header";
        llStatus: Boolean;
        lcOrderNo: Text;
        lcShipNO: Text;
        SuppressCommit: Boolean;
        Base64Conver: Codeunit "Base64 Convert";
        InStream: InStream;
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        SalesShipmentHeader: Record "Sales Shipment Header";
        NamePDF: Text;
        Nametxt: Text;
        PostedCustOrder: Record "LSC Posted CO Header";
    begin
        CLEAR(JsonRequestStr);
        CLEAR(APIResult);
        CLEAR(RecRef);
        CLEAR(ErrorMsg);
        if not PostedCustOrder.Get(rec."BPC.Sales Order No.") then
            PostedCustOrder.Init();
        RetailSetup.Get();
        Company_Name := RetailSetup."BPC.Interface Company";
        InterfaceData.CheckConfigInterface2();
        FunctionsName := 'PostSalesShipment_POS';
        DocumentNo := Rec."BPC.Sales Order No.";
        JsonRequestStr := Convert.ToBase64(CreateJsonRequest_POS(FunctionsName, Rec));
        JsonRequestStr := STRSUBSTNO('{company:"%1",warehouse:"%2",data:"%3"}', Company_Name, PostedCustOrder."BPC.Collect Location", JsonRequestStr);
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
                MESSAGE('SO No. %1 has been Shipping.', lcOrderNo);
                EXIT(TRUE);
            END;
        END ELSE BEGIN
            MESSAGE('%1', GETLASTERRORTEXT);
        END;
    end;

    local procedure GenerateTempSalesOrder(IsGenHeader: Boolean; APIResult: Text; SalesHeader: Record "Sales Header"; Location: text)
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
        lineno: Integer;
        InsertSalesLine: Boolean;
        LineDiscountAmount: Decimal;
        Amount: Decimal;
        OutstandingQuantity: Decimal;
        PostedCustOrder: Record "LSC Posted CO Header";
        SalesShipment: Record "Sales Shipment Header";
        ChekhSalesHeader: Record "Sales Header";
        DELETEALLSalesHeader: Record "Sales Header";
        DELETEALLSalesLine: Record "Sales Line";
        countline: Integer;
        maxcountline: Integer;
        pItem: Record Item;
        Branch: Text[5];
        HeaderOffice: Boolean;
        HeaderOfficeText: Text;
        SalesLine: Record "Sales Line";
        StatusSO: Text;
    begin
        if IsGenHeader then
            TempSalesHeader.DELETEALL;

        TempSalesLine.DELETEALL;
        MinusQtyFound := FALSE;
        CLEAR(JSONMgt);
        CLEAR(JObjectData);
        CLEAR(JArrayData);
        Clear(CustomerNo);
        Clear(store);
        Clear(ShipmentMethodCode);
        CLEAR(JSUnitConArray);
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
        //Window.OPEN('Generate Sales No. #1############################');
        JArrayData.ReadFrom(APIResult);
        FOREACH JToken IN JArrayData DO BEGIN
            JObjectData := JToken.AsObject();
            IF IsGenHeader THEN BEGIN
                TempSalesHeader.INIT;
                if JObjectData.get('SalesOrder', JToken) then
                    TempSalesHeader."No." := JToken.AsValue().AsCode();

                DELETEALLSalesHeader.Reset();
                DELETEALLSalesHeader.SetRange("No.", TempSalesHeader."No.");
                if DELETEALLSalesHeader.FindSet() then begin
                    DELETEALLSalesHeader.Delete();
                    DELETEALLSalesLine.Reset();
                    DELETEALLSalesLine.SetRange("Document No.", DELETEALLSalesHeader."No.");
                    DELETEALLSalesLine.SetRange("Document Type", DELETEALLSalesHeader."Document Type");
                    if DELETEALLSalesLine.FindSet() then
                        DELETEALLSalesLine.DeleteAll();
                end;

                ChekhSalesHeader.Reset();
                ChekhSalesHeader.SetRange(ChekhSalesHeader."Document Type", ChekhSalesHeader."Document Type"::Order);
                ChekhSalesHeader.SetRange("No.", TempSalesHeader."No.");
                ChekhSalesHeader.SETRANGE("LSC Store No.", Location);
                if not ChekhSalesHeader.FindSet() then begin
                    PostedCustOrder.Reset();
                    PostedCustOrder.SetRange("Document ID", TempSalesHeader."No.");
                    if not PostedCustOrder.FindSet() then begin
                        SalesShipment.Reset();
                        SalesShipment.SetRange("Order No.", TempSalesHeader."No.");
                        if not SalesShipment.FindSet() then begin
                            TempSalesHeader."Document Type" := TempSalesHeader."Document Type"::Order;
                            if JObjectData.get('CustomerName', JToken) then
                                CustomerName := JToken.AsValue().AsText();
                            if JObjectData.get('CustomerAccount', JToken) then begin
                                CustomerNo := JToken.AsValue().AsCode();
                                TempSalesHeader."Sell-to Customer No." := CustomerNo;
                            end;
                            if JObjectData.get('Branch', JToken) then
                                Branch := JToken.AsValue().AsText();
                            if JObjectData.get('HeaderOffice', JToken) then begin
                                HeaderOfficeText := JToken.AsValue().AsText();
                                if HeaderOfficeText = 'Yes' then
                                    HeaderOffice := true
                                else
                                    HeaderOffice := false;
                            end;
                            TempSalesHeader."Sell-to Customer Name" := CustomerName;
                            if JObjectData.get('Warehouse', JToken) then begin
                                store := JToken.AsValue().AsCode();
                                TempSalesHeader."Location Code" := store;
                                TempSalesHeader."bpc.Location Code" := store;
                            end;
                            StoreLocation.RESET;
                            StoreLocation.SETRANGE("Location Code", TempSalesHeader."Location Code");
                            IF StoreLocation.FINDSET THEN
                                TempSalesHeader."LSC Store No." := StoreLocation."Store No.";
                            if JObjectData.get('SalesTaxGroup', JToken) then
                                TempSalesHeader."VAT Bus. Posting Group" := JToken.AsValue().AsCode();

                            if JObjectData.get('PlatformOrder', JToken) then
                                if JToken.AsValue().AsText() <> '' then
                                    TempSalesHeader."BPC.Reference Online Order" := JToken.AsValue().AsText();

                            if JObjectData.get('CustomerReference', JToken) then
                                if JToken.AsValue().AsText() <> '' then
                                    TempSalesHeader."BPC.Reference Online Order" := JToken.AsValue().AsText();

                            if JObjectData.get('DeliveryPostalCode', JToken) then
                                TempSalesHeader."Ship-to Post Code" := JToken.AsValue().AsText();
                            TempSalesHeader."Ship-to Code" := CopyStr(CustomerNo, 1, 10);
                            if JObjectData.get('DeliveryAddress', JToken) then begin
                                ShiptoAddress := JToken.AsValue().AsText();
                                TempSalesHeader."Ship-to Address" := CopyStr(ShiptoAddress, 1, 100);
                            end;
                            if JObjectData.get('DeliveryAddress2', JToken) then begin
                                ShiptoAddress2 := JToken.AsValue().AsText();
                                TempSalesHeader."Ship-to Address 2" := CopyStr(ShiptoAddress2, 1, 50);
                            end;
                            TempSalesHeader."Prices Including VAT" := true;
                            if JObjectData.get('DeliveryPostalCode', JToken) then
                                TempSalesHeader."Ship-to Post Code" := JToken.AsValue().AsText();
                            if JObjectData.get('DeliveryCity', JToken) then
                                TempSalesHeader."Ship-to City" := JToken.AsValue().AsText();
                            if JObjectData.get('DeliveryCountry', JToken) then
                                TempSalesHeader."Ship-to Country/Region Code" := JToken.AsValue().AsText();
                            if TempSalesHeader."Ship-to Country/Region Code" = 'THA' then
                                TempSalesHeader."Ship-to Country/Region Code" := 'TH';
                            if JObjectData.get('DeliveryName', JToken) then
                                TempSalesHeader."Ship-to Name" := JToken.AsValue().AsText();
                            TempSalesHeader."Bill-to Customer No." := CustomerNo;
                            if JObjectData.get('InvoiceName', JToken) then
                                TempSalesHeader."Bill-to Name" := JToken.AsValue().AsText();
                            if JObjectData.get('InvoiceAddress', JToken) then
                                TempSalesHeader."Bill-to Address" := JToken.AsValue().AsText();
                            if JObjectData.get('InvoiceAddress2', JToken) then
                                TempSalesHeader."Bill-to Address 2" := CopyStr(JToken.AsValue().AsText(), 1, 50);
                            if JObjectData.get('InvoicePostalCode', JToken) then
                                TempSalesHeader."Bill-to Post Code" := JToken.AsValue().AsText();
                            if JObjectData.get('InvoiceCity', JToken) then
                                TempSalesHeader."Bill-to City" := JToken.AsValue().AsText();
                            if JObjectData.get('InvoiceCountry', JToken) then
                                TempSalesHeader."Bill-to Country/Region Code" := JToken.AsValue().AsText();
                            if TempSalesHeader."Bill-to Country/Region Code" = 'THA' then
                                TempSalesHeader."Bill-to Country/Region Code" := 'TH';
                            TempSalesHeader."Sell-to Address" := TempSalesHeader."Bill-to Address";
                            TempSalesHeader."Sell-to Address 2" := TempSalesHeader."Bill-to Address 2";
                            TempSalesHeader."Sell-to Post Code" := TempSalesHeader."Bill-to Post Code";
                            TempSalesHeader."Sell-to City" := TempSalesHeader."Bill-to City";
                            TempSalesHeader."Sell-to Country/Region Code" := TempSalesHeader."Bill-to Country/Region Code";

                            if JObjectData.get('InvoiceRegistrationID', JToken) then
                                TempSalesHeader."VAT Registration No." := JToken.AsValue().AsText();
                            if JObjectData.get('TotalDiscount', JToken) then
                                TempSalesHeader."Invoice Discount Value" := JToken.AsValue().AsDecimal();
                            if JObjectData.get('ModeOfDelivery', JToken) then begin
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

                            if JObjectData.get('RequestedShipDate', JToken) then begin
                                RequestedShipDate := JToken.AsValue().AsDateTime();
                                TempSalesHeader."Shipment Date" := DT2Date(RequestedShipDate);
                            end;
                            if JObjectData.get('RequestedReceiptDate', JToken) then begin
                                RequestedReceiptDate := JToken.AsValue().AsDateTime();
                                TempSalesHeader."Requested Delivery Date" := DT2Date(RequestedReceiptDate);
                            end;
                            if JObjectData.get('DepositInvoiceNo', JToken) then begin
                                DepositInvoiceNo := JToken.AsValue().AsText();
                            end;
                            if JObjectData.get('DepositCurrency', JToken) then begin
                                DepositCurrency := JToken.AsValue().AsText();
                            end;
                            if JObjectData.get('DepositInvoiceAmount', JToken) then begin
                                DepositInvoiceAmount := JToken.AsValue().AsDecimal();
                            end;
                            if DepositInvoiceNo <> '' then begin

                                if not LSCRetailUser.get(userid) then
                                    LSCRetailUser.Init();

                                LSCPOSDataEntry.Reset();
                                LSCPOSDataEntry.SetRange("Entry Code", DepositInvoiceNo);
                                LSCPOSDataEntry.SetRange("Entry Type", 'DEPOSIT');
                                if not LSCPOSDataEntry.findset then begin
                                    LSCPOSDataEntry.Init();
                                    LSCPOSDataEntry."Entry Code" := DepositInvoiceNo;
                                    LSCPOSDataEntry."Entry Type" := 'DEPOSIT';
                                    LSCPOSDataEntry."Currency Code" := DepositCurrency;
                                    LSCPOSDataEntry."Created in Store No." := LSCRetailUser."Store No.";
                                    LSCPOSDataEntry."Date Created" := Today;
                                    LSCPOSDataEntry."Created by Receipt No." := TempSalesHeader."No.";
                                    POSApplEntry.reset;
                                    POSApplEntry.SetCurrentKey("Replication Counter");
                                    if POSApplEntry.Find('+') then
                                        LSCPOSDataEntry."Replication Counter" := POSApplEntry."Replication Counter" + 1
                                    else
                                        LSCPOSDataEntry."Replication Counter" := 1;

                                    LSCPOSDataEntry.Validate(Amount, DepositInvoiceAmount);
                                    LSCPOSDataEntry.Insert();
                                end else begin
                                    LSCPOSDataEntry."Currency Code" := DepositCurrency;
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
                                    LSCVoucherEntries."Voucher No." := DepositInvoiceNo;
                                    LSCVoucherEntries.Amount := DepositInvoiceAmount;
                                    LSCVoucherEntries."Voucher Type" := 'DEPOSIT';
                                    LSCVoucherEntries."Currency Code" := DepositCurrency;
                                    LSCVoucherEntries."Store Currency Code" := DepositCurrency;
                                    VoucherEntries.Reset;
                                    VoucherEntries.SetCurrentKey("Replication Counter");
                                    if VoucherEntries.Find('+') then
                                        LSCVoucherEntries."Replication Counter" := VoucherEntries."Replication Counter" + 1
                                    else
                                        LSCVoucherEntries."Replication Counter" := 1;
                                    LSCVoucherEntries.Date := Today;
                                    LSCVoucherEntries.Time := Time;
                                    LSCVoucherEntries.insert;
                                end else begin
                                    LSCVoucherEntries."Currency Code" := DepositCurrency;
                                    LSCVoucherEntries."Store Currency Code" := DepositCurrency;
                                    LSCVoucherEntries.Amount := DepositInvoiceAmount;
                                    LSCVoucherEntries."Voucher Type" := 'DEPOSIT';
                                    LSCVoucherEntries.Modify();
                                end;

                            end;
                            if JObjectData.get('Status', JToken) then
                                StatusSO := JToken.AsValue().AsText();
                            if StatusSO = 'Canceled' then
                                TempSalesHeader.Status := TempSalesHeader.Status::Cancel;
                            InterfaceData.InsertCustomer(TempSalesHeader, HeaderOffice, Branch);
                            TempSalesHeader."BPC.Interface" := TRUE;
                            TempSalesHeader."BPC.Active" := TRUE;
                            TempSalesHeader.INSERT;
                        end;
                    end;
                end;
            END ELSE BEGIN
                // SalesLine.Reset();
                // SalesLine.SetRange("Document Type", SalesHeader."Document Type");
                // SalesLine.SetRange("Document No.", SalesHeader."No.");
                // if not SalesLine.FindSet() then begin
                TempSalesLine.INIT;
                TempSalesLine."Document Type" := SalesHeader."Document Type";
                TempSalesLine."Document No." := SalesHeader."No.";
                TempSalesLine."Sell-to Customer No." := SalesHeader."Sell-to Customer No.";
                lineno := lineno + 10000;
                TempSalesLine."Line No." := lineno;
                TempSalesLine.Type := TempSalesLine.Type::Item;
                if JObjectData.get('ItemNumber', JToken) then
                    TempSalesLine."No." := JToken.AsValue().AsCode();
                if JObjectData.get('ProductName', JToken) then
                    TempSalesLine.Description := JToken.AsValue().AsText();
                TempSalesLine."Location Code" := SalesHeader."Location Code";
                IF TempSalesLine."Location Code" <> SalesHeader."Location Code" THEN
                    MESSAGE('Location %1 not found in store %2', TempSalesLine."Location Code", SalesHeader."Location Code");

                if JObjectData.get('Quantity', JToken) then
                    TempSalesLine.Quantity := JToken.AsValue().AsDecimal();
                if TempSalesLine.Quantity <> 0 then begin
                    if item.get(TempSalesLine."No.") then begin
                        if item."Assembly BOM" then
                            TempSalesLine."Qty. to Assemble to Order" := TempSalesLine.Quantity;
                    end;
                end;
                if JObjectData.get('UnitPrice', JToken) then
                    TempSalesLine."Unit Price" := JToken.AsValue().AsDecimal();
                if JObjectData.get('Unit', JToken) then
                    TempSalesLine."Unit of Measure Code" := JToken.AsValue().AsCode();
                if JObjectData.get('VATPercent', JToken) then
                    TempSalesLine."VAT %" := JToken.AsValue().AsDecimal();
                if JObjectData.get('TotalLineDiscount', JToken) then
                    TempSalesLine."Line Discount Amount" := JToken.AsValue().AsDecimal();
                if JObjectData.get('NetAmount', JToken) then
                    TempSalesLine.Amount := JToken.AsValue().AsDecimal();
                if JObjectData.get('RemainQuantity', JToken) then
                    TempSalesLine."Outstanding Quantity" := JToken.AsValue().AsDecimal();
                if JObjectData.get('Warehouse', JToken) then
                    TempSalesLine."Location Code" := JToken.AsValue().AsCode();
                if TempSalesLine."Location Code" = '' then
                    Error('SO: %1 กำหนด Warehouse ไม่ถูกต้อง', TempSalesLine."Document No.");

                if JObjectData.get('UnitPrice', JToken) then
                    TempSalesLine."Unit Price" := JToken.AsValue().AsDecimal();
                if JObjectData.get('BatchNumber', JToken) then
                    Lot := JToken.AsValue().AsCode();
                if JObjectData.get('SerialNumber', JToken) then
                    Serial := JToken.AsValue().AsCode();
                if (Lot <> '') or (Serial <> '') then begin
                    ReservationEntry.Reset();
                    ReservationEntry.SetRange("Item No.", TempSalesLine."No.");
                    ReservationEntry.SetRange("Source ID", TempSalesLine."Document No.");
                    ReservationEntry.SetRange("Source Type", 37);
                    ReservationEntry.SetRange("Source Subtype", 1);
                    ReservationEntry.SetRange("Source Ref. No.", TempSalesLine."Line No.");
                    if not ReservationEntry.FindSet() then begin
                        ReservationEntry.init();
                        ReservationEntry."Entry No." := InterfaceData.GetLastEntry;
                        ReservationEntry."Source Type" := 37;
                        ReservationEntry."Source ID" := TempSalesLine."Document No.";
                        ReservationEntry."Item No." := TempSalesLine."No.";
                        ReservationEntry."Source Subtype" := 1;
                        ReservationEntry."Source Ref. No." := TempSalesLine."Line No.";
                        ReservationEntry.Positive := true;
                        ReservationEntry."Reservation Status" := ReservationEntry."Reservation Status"::Surplus;
                        ReservationEntry."Created By" := UserId;
                        ReservationEntry."Creation Date" := Today;
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
                    end;
                end;
                TempSalesLine."BPC.Not Check AutoAsmToOrder" := false;
                Clear(bomLineNo);
                Clear(bomItemNo);
                Clear(bomQuantity);
                InsertSalesLine := true;
                if JObjectData.get('BOM', JToken) then begin
                    JSUnitConArray := JToken.AsArray();
                    foreach JUnitCon in JSUnitConArray do begin
                        JUnitConOJ := JUnitCon.AsObject();
                        if JUnitConOJ.Get('bomLineNo', JTypeToken) then begin
                            bomLineNo := JTypeToken.AsValue().AsInteger();
                        end;
                        if JUnitConOJ.Get('bomItemNo', JTypeToken) then begin
                            bomItemNo := JTypeToken.AsValue().AsCode();
                        end;
                        if JUnitConOJ.Get('bomQuantity', JTypeToken) then begin
                            bomQuantity := JTypeToken.AsValue().AsDecimal();
                        end;
                        // insertAssembly BOM
                        if bomItemNo <> '' then begin
                            InsertSalesLine := false
                        end;
                    end;
                end;
                Clear(countline);
                InsertSalesLine := true;
                pItem.Reset();
                pItem.SetRange("No.", TempSalesLine."No.");
                pItem.SetRange("Item Tracking Code", 'SERIAL');
                if pItem.FindSet() then begin
                    maxcountline := ABS(TempSalesLine.Quantity);
                    LineDiscountAmount := TempSalesLine."Line Discount Amount" / TempSalesLine.Quantity;
                    Amount := TempSalesLine.Amount / TempSalesLine.Quantity;
                    OutstandingQuantity := TempSalesLine."Outstanding Quantity" / TempSalesLine.Quantity;
                    repeat
                        countline += 1;
                        TempSalesLine1.init;
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

                        // TempSalesLine1."Qty. to Assemble to Order" := 1;
                        // TempSalesLine1."Qty. to Asm. to Order (Base)" := 1;
                        // TempSalesLine1."BPC.Not Check AutoAsmToOrder" := true;
                        // INSERT_AssemblyBOM(TempSalesLine1);

                        TempSalesLine1."BPC.Interface" := TRUE;
                        TempSalesLine1."BPC.Active" := TRUE;
                        IF TempSalesLine1."Outstanding Quantity" = 0 THEN
                            TempSalesLine1."BPC.Active" := FALSE;
                        TempSalesLine.TransferFields(TempSalesLine1);
                        TempSalesLine.Insert();
                    UNTIL countline = maxcountline;
                    InsertSalesLine := false;
                END;
                TempSalesLine."BPC.Interface" := TRUE;
                TempSalesLine."BPC.Active" := TRUE;
                IF TempSalesLine."Outstanding Quantity" = 0 THEN
                    TempSalesLine."BPC.Active" := FALSE;
                if InsertSalesLine then
                    TempSalesLine.INSERT;
                IF MinusQtyFound AND (TempSalesLine.Quantity < 0) THEN
                    MinusQtyFound := TRUE;
            END;
        END;
        // end;

        //Window.CLOSE;
    end;

    procedure CreateJsonRequest_POS(SelectionFunctions: Text; LSCTransactionHeader: Record "LSC Transaction Header"): Text
    var
        PostedCustomerOrderLine: Record "LSC Posted Customer Order Line";
        PostedCustomerOrderHeader: Record "LSC Posted CO Header";
        LSCTransSalesEntry: Record "LSC Trans. Sales Entry";
        // LSCTransactionHeader: Record "LSC Transaction Header";
        Customer: Record Customer;
        CheckDoc: text;
        LineNo: Integer;
    begin
        CLEAR(JsonUtil);
        CASE SelectionFunctions OF
            'PostSalesShipment_POS':
                BEGIN
                    // LSCTransactionHeader.Reset();
                    // LSCTransactionHeader.SetRange("BPC.Sales Order No.", No);
                    // if not LSCTransactionHeader.FindSet() then
                    //     LSCTransactionHeader.Init();

                    PostedCustomerOrderHeader.RESET;
                    PostedCustomerOrderHeader.SetRange("Document ID", LSCTransactionHeader."BPC.Sales Order No.");
                    IF PostedCustomerOrderHeader.FINDSET THEN BEGIN
                        JsonUtil.StartJSon;
                        // Header
                        if not Customer.get(LSCTransactionHeader."Customer No.") then
                            Customer.init;

                        JsonUtil.AddToJSon('SOH_SONo', PostedCustomerOrderHeader."Document ID");
                        JsonUtil.AddToJSon('SOH_CustShipNo', '');
                        JsonUtil.AddToJSon('SOH_SellToCustNo', LSCTransactionHeader."Customer No.");
                        JsonUtil.AddToJSon('SOH_PostingDate', Format(LSCTransactionHeader."BPC.Sales Order Posting Date", 0, '<Year4>-<Month,2>-<Day,2>'));
                        JsonUtil.AddToJSon('SOH_DocumentDate', Format(LSCTransactionHeader."BPC.Sales Order Document Date", 0, '<Year4>-<Month,2>-<Day,2>'));
                        JsonUtil.AddToJSon('SOH_CustName', Customer.Name);
                        if Customer."VAT Registration No." <> '' then
                            JsonUtil.AddToJSon('SOH_VATRegistrationNo', Customer."VAT Registration No.");

                        if LSCTransactionHeader."BPC Full Tax No." = '' then
                            JsonUtil.AddToJSon('SOH_FullTaxNo', GenFullTaxNo(LSCTransactionHeader))
                        else
                            JsonUtil.AddToJSon('SOH_FullTaxNo', LSCTransactionHeader."BPC.Full Tax No.");

                        JsonUtil.AddToJSon('SOH_HeadOffice', Customer."BPC Head Office");
                        JsonUtil.AddToJSon('SOH_BranchNo', Customer."BPC Branch No.");
                        JsonUtil.AddToJSon('SOH_Date', Format(LSCTransactionHeader.Date, 0, '<Year4>-<Month,2>-<Day,2>'));

                        if PostedCustomerOrderHeader."BPC.Bill-to Name" = '' then begin
                            JsonUtil.AddToJSon('SOH_InvoiceName', Customer.Name);
                            JsonUtil.AddToJSon('SOH_InvoiceAddress', Customer.Address);
                            JsonUtil.AddToJSon('SOH_InvoiceAddress2', Customer."Address 2".Replace(' ', ','));
                            JsonUtil.AddToJSon('SOH_InvoiceCity', Customer.City);
                            // JsonUtil.AddToJSon('SOH_InvoiceCountry', Customer."Country/Region Code");
                            if (Customer."Country/Region Code" = 'TH') or (Customer."Country/Region Code" = '') then
                                JsonUtil.AddToJSon('SOH_InvoiceCountry', 'THA')
                            else
                                JsonUtil.AddToJSon('SOH_InvoiceCountry', Customer."Country/Region Code");

                            JsonUtil.AddToJSon('SOH_InvoicePostalCode', Customer."Post Code");
                        end else begin
                            JsonUtil.AddToJSon('SOH_InvoiceName', PostedCustomerOrderHeader."BPC.Bill-to Name");
                            JsonUtil.AddToJSon('SOH_InvoiceAddress', PostedCustomerOrderHeader."BPC.Bill-to Address");
                            //JsonUtil.AddToJSon('SOH_InvoiceAddress2', PostedCustomerOrderHeader."BPC.Bill-to Address 2".Replace(' ', ','));
                            JsonUtil.AddToJSon('SOH_InvoiceCity', PostedCustomerOrderHeader.City);
                            // JsonUtil.AddToJSon('SOH_InvoiceCountry', Customer."Country/Region Code");
                            if (PostedCustomerOrderHeader."BPC.Bill-to County" = 'TH') or (PostedCustomerOrderHeader."BPC.Bill-to County" = '') then
                                JsonUtil.AddToJSon('SOH_InvoiceCountry', 'THA')
                            else
                                JsonUtil.AddToJSon('SOH_InvoiceCountry', PostedCustomerOrderHeader."BPC.Bill-to County");

                            JsonUtil.AddToJSon('SOH_InvoicePostalCode', PostedCustomerOrderHeader."BPC.Bill-to Post Code");
                        end;
                        PostedCustomerOrderLine.RESET;
                        PostedCustomerOrderLine.SETRANGE("Document ID", PostedCustomerOrderHeader."Document ID");
                        PostedCustomerOrderLine.SETFILTER(Quantity, '<>%1', 0);
                        IF PostedCustomerOrderLine.FINDSET THEN BEGIN
                            JsonUtil.StartJSonArray('SOLine');
                            Clear(LineNo);
                            Clear(CheckDoc);
                            REPEAT
                                JsonUtil.StartJSon;
                                if CheckDoc <> PostedCustomerOrderLine.Number then begin
                                    CheckDoc := PostedCustomerOrderLine.Number;
                                    LineNo += 10000;
                                end;
                                JsonUtil.AddToJSon('SOL_LineNo', LineNo);
                                JsonUtil.AddToJSon('SOL_ItemNo', PostedCustomerOrderLine.Number);
                                JsonUtil.AddToJSon('SOL_Warehouse', PostedCustomerOrderHeader."BPC.Collect Location");
                                JsonUtil.AddToJSon('SOL_QTYtopacking', PostedCustomerOrderLine.Quantity);
                                JsonUtil.AddToJSon('SOL_Batch', '');

                                LSCTransSalesEntry.Reset();
                                LSCTransSalesEntry.SetRange("Store No.", LSCTransactionHeader."Store No.");
                                LSCTransSalesEntry.SetRange("Transaction No.", LSCTransactionHeader."Transaction No.");
                                LSCTransSalesEntry.SetRange("Receipt No.", LSCTransactionHeader."Receipt No.");
                                LSCTransSalesEntry.SetRange("POS Terminal No.", LSCTransactionHeader."POS Terminal No.");
                                LSCTransSalesEntry.SetRange("Line No.", PostedCustomerOrderLine."Original Line No.");
                                if LSCTransSalesEntry.FindSet() then begin
                                    JsonUtil.StartJSonArray('SOL_Serial');
                                    repeat
                                        JsonUtil.StartJSon;
                                        JsonUtil.AddToJSon('Serial_ItemNo', LSCTransSalesEntry."Item No.");
                                        JsonUtil.AddToJSon('Serial_No', LSCTransSalesEntry."Serial No.");
                                        JsonUtil.AddToJSon('Serial_Qty', Abs(LSCTransSalesEntry.Quantity));
                                        JsonUtil.EndJSon;
                                    until LSCTransSalesEntry.Next() = 0;
                                    JsonUtil.EndJSonArray;
                                end else begin
                                    JsonUtil.StartJSonArray('SOL_Serial');
                                    JsonUtil.StartJSon;
                                    JsonUtil.AddToJSon('Serial_ItemNo', PostedCustomerOrderLine.Number);
                                    JsonUtil.AddToJSon('Serial_No', '');
                                    JsonUtil.AddToJSon('Serial_Qty', PostedCustomerOrderLine.Quantity);
                                    JsonUtil.EndJSon;
                                    JsonUtil.EndJSonArray;
                                end;
                                JsonUtil.EndJSon;
                            UNTIL PostedCustomerOrderLine.NEXT = 0;
                            JsonUtil.EndJSonArray;
                        END;
                        JsonUtil.EndJSon
                    END;
                END;
        END;
        EXIT(JsonUtil.GetJSon());
    END;

    local procedure InsertSalesOrderHeader(IsGenHeader: Boolean; pStoreNo: Code[10]; pLocCode: Code[10]; Var pSalesHeader: Record "sales Header")
    var
        SalesHeader: Record "sales Header";
        SalesHeader1: Record "sales Header";
        SalesLine: Record "sales Line";
        Item: Record Item;
        Item1: Record Item;
        DataInsert: Boolean;
        Status_Var: Option Open,Released,"Pending Approval","Pending Prepayment";
        SalesShipmentHeader: Record "Sales Shipment Header";
        InterfaceDocumentStatus: Record "BPC.Interface Document Status";
        UOMMgt: Codeunit "Unit of Measure Management";
        Customer: Record Customer;
        CalcDiscByType: Codeunit 56;
    begin
        Window.OPEN('Insert sales No. #1############################');

        IF IsGenHeader THEN BEGIN
            TempSalesHeader.RESET;
            TempSalesHeader.SETRANGE("LSC Store No.", pStoreNo);
            IF TempSalesHeader.FINDSET THEN BEGIN
                REPEAT
                    // if TempSalesHeader."No." = 'SOS123-00274' then
                    //     Message('');
                    SalesShipmentHeader.Reset();
                    SalesShipmentHeader.SetRange("Order No.", TempSalesHeader."No.");
                    if not SalesShipmentHeader.FINDSET then begin
                        SalesHeader.RESET;
                        SalesHeader.SETRANGE("Document Type", TempSalesHeader."Document Type");
                        SalesHeader.SETRANGE("No.", TempSalesHeader."No.");
                        //SalesHeader.SETRANGE("LSC Store No.", TempSalesHeader."LSC Store No.");
                        // SalesHeader.SetFilter("status", '<>%1', TempSalesHeader.Status::Cancel);
                        IF NOT SalesHeader.FINDFIRST THEN BEGIN
                            Window.UPDATE(1, TempSalesHeader."No.");
                            // INSERT
                            SalesHeader.INIT;
                            SalesHeader.TRANSFERFIELDS(TempSalesHeader);
                            SalesHeader.SetHideValidationDialog(TRUE);
                            SalesHeader.Status := SalesHeader.Status::Open;
                            SalesHeader.Insert();
                            SalesHeader."Document Date" := Today;
                            SalesHeader."Posting Date" := Today;
                            SalesHeader.VALIDATE("Sell-to Customer No.", TempSalesHeader."Sell-to Customer No.");
                            SalesHeader."Sell-to Customer Name" := TempSalesHeader."Sell-to Customer Name";
                            // if TempSalesHeader."Location Code" <> '' then
                            //     SalesHeader.VALIDATE("Location Code", TempSalesHeader."Location Code");
                            SalesHeader.VALIDATE("LSC Store No.", TempSalesHeader."LSC Store No.");
                            if TempSalesHeader."Location Code" <> '' then
                                SalesHeader."Location Code" := TempSalesHeader."Location Code";
                            if not Customer.get(TempSalesHeader."Sell-to Customer No.") then
                                Customer.Init();
                            SalesHeader.VALIDATE("VAT Bus. Posting Group", Customer."VAT Bus. Posting Group");
                            SalesHeader.VALIDATE("Gen. Bus. Posting Group", Customer."Gen. Bus. Posting Group");
                            SalesHeader.VALIDATE("Bill-to Customer No.", TempSalesHeader."Bill-to Customer No.");
                            SalesHeader.VALIDATE("Invoice Discount Value", TempSalesHeader."Invoice Discount Value");
                            if TempSalesHeader."Ship-to Code" <> '' then
                                SalesHeader.VALIDATE("Ship-to Code", TempSalesHeader."Ship-to Code");

                            SalesHeader.VALIDATE("Prices Including VAT", TempSalesHeader."Prices Including VAT");

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
                            SalesHeader."BPC.Interface" := TRUE;
                            SalesHeader."BPC.Active" := TRUE;
                            // SalesHeader.Status := SalesHeader.Status::Open;
                            SalesHeader.MODIFY();

                            //SalesHeader.VALIDATE("Prices Including VAT", TempSalesHeader."Prices Including VAT");

                            if TempSalesHeader.Status = TempSalesHeader.Status::Cancel then
                                SalesHeader.Status := SalesHeader.Status::Cancel
                            else begin
                                GetSalesLine(SalesHeader);
                                SalesHeader.Status := SalesHeader.Status::Released;
                            end;
                            SalesHeader.MODIFY();
                            CalcDiscByType.ApplyInvDiscBasedOnAmt(SalesHeader."Invoice Discount Value", SalesHeader)
                        END ELSE BEGIN
                            // MODIFY
                            if SalesHeader.Status <> SalesHeader.Status::Cancel then begin
                                SalesHeader.Status := SalesHeader.Status::Open;
                                SalesHeader."Document Type" := TempSalesHeader."Document Type";
                                if not Customer.get(TempSalesHeader."Sell-to Customer No.") then
                                    Customer.Init();

                                //if (Customer."Gen. Bus. Posting Group" <> '') and (Customer."VAT Bus. Posting Group" <> '') then
                                // SalesHeader.VALIDATE("Sell-to Customer No.", TempSalesHeader."Sell-to Customer No.");
                                SalesHeader."Sell-to Customer No." := TempSalesHeader."Sell-to Customer No.";

                                if SalesHeader."Gen. Bus. Posting Group" = '' then
                                    SalesHeader.VALIDATE("Gen. Bus. Posting Group", Customer."Gen. Bus. Posting Group");
                                if SalesHeader."Gen. Bus. Posting Group" = '' then
                                    SalesHeader.VALIDATE("VAT Bus. Posting Group", Customer."VAT Bus. Posting Group");

                                SalesHeader.VALIDATE("LSC Store No.", TempSalesHeader."LSC Store No.");
                                SalesHeader.VALIDATE("Invoice Discount Value", TempSalesHeader."Invoice Discount Value");
                                if TempSalesHeader."Ship-to Code" <> '' then
                                    SalesHeader.VALIDATE("Ship-to Code", TempSalesHeader."Ship-to Code");
                                // if TempSalesHeader."Location Code" <> '' then
                                //     SalesHeader.Validate("Location Code", TempSalesHeader."Location Code");
                                SalesHeader.Validate("LSC Store No.", TempSalesHeader."LSC Store No.");

                                if SalesHeader."Prices Including VAT" <> TempSalesHeader."Prices Including VAT" then
                                    SalesHeader.VALIDATE("Prices Including VAT", TempSalesHeader."Prices Including VAT");
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
                                SalesHeader."Sell-to Address" := TempSalesHeader."Sell-to Address";
                                SalesHeader."Sell-to Address 2" := TempSalesHeader."Sell-to Address 2";
                                SalesHeader."Sell-to Post Code" := TempSalesHeader."Sell-to Post Code";
                                SalesHeader."Sell-to City" := TempSalesHeader."Sell-to City";
                                SalesHeader."Sell-to Contact" := TempSalesHeader."Sell-to Contact";
                                SalesHeader."BPC.Location Code" := TempSalesHeader."BPC.Location Code";
                                SalesHeader."BPC.Reference Online Order" := TempSalesHeader."BPC.Reference Online Order";
                                SalesHeader."BPC.Interface" := TRUE;
                                SalesHeader."BPC.Active" := TRUE;
                                SalesHeader.MODIFY();


                                //SalesHeader.VALIDATE("Prices Including VAT", TempSalesHeader."Prices Including VAT");
                                if TempSalesHeader.Status = TempSalesHeader.Status::Cancel then
                                    SalesHeader.Status := SalesHeader.Status::Cancel
                                else begin
                                    GetSalesLine(SalesHeader);
                                    SalesHeader.Status := SalesHeader.Status::Released;
                                end;

                                SalesHeader.MODIFY();
                                CalcDiscByType.ApplyInvDiscBasedOnAmt(SalesHeader."Invoice Discount Value", SalesHeader)
                            end;
                        END;
                    end;
                UNTIL TempSalesHeader.NEXT = 0;
            END;
        END;
        Window.CLOSE;
        COMMIT;
    end;

    local procedure InsertSalesOrderLine(Var pSalesHeader: Record "sales Header") return: Boolean
    var
        SalesHeader: Record "sales Header";
        SalesHeader1: Record "sales Header";
        SalesLine: Record "sales Line";
        DeleteSalesLine: Record "sales Line";
        Item: Record Item;
        Item1: Record Item;
        DataInsert: Boolean;
        Status_Var: Option Open,Released,"Pending Approval","Pending Prepayment";
        SalesShipmentHeader: Record "Sales Shipment Header";
        InterfaceDocumentStatus: Record "BPC.Interface Document Status";
        UOMMgt: Codeunit "Unit of Measure Management";
        Customer: Record Customer;
        CalcDiscByType: Codeunit "Sales - Calc Discount By Type";
    begin
        //Window.OPEN('Insert sales No. #1############################');
        CLEAR(JsonUtil);
        TempSalesLine.RESET;
        IF TempSalesLine.FINDSET THEN BEGIN
            // Clear Active ++
            SalesLine.RESET;
            SalesLine.SETRANGE("Document Type", TempSalesLine."Document Type");
            SalesLine.SETRANGE("Document No.", TempSalesLine."Document No.");
            SalesLine.SETRANGE("BPC.Active", TRUE);
            IF SalesLine.FINDSET THEN
                SalesLine.MODIFYALL("BPC.Active", FALSE);
            // Clear Active --
            JsonUtil.StartJSon;
            REPEAT
                IF NOT SalesLine.GET(TempSalesLine."Document Type", TempSalesLine."Document No.", TempSalesLine."Line No.") THEN BEGIN
                    Window.UPDATE(1, TempSalesLine."Document No.");
                    SalesLine.INIT;
                    SalesLine.TRANSFERFIELDS(TempSalesLine);
                    SalesLine.INSERT;
                    if not Item1.get(TempSalesLine."No.") then
                        Item1.Init();
                    SalesLine."Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(Item1, TempSalesLine."Unit of Measure Code");
                    SalesLine.VALIDATE(Quantity, TempSalesLine.Quantity);
                    SalesLine.VALIDATE("Sell-to Customer No.", pSalesHeader."Sell-to Customer No.");
                    SalesLine.VALIDATE("Bill-to Customer No.", pSalesHeader."Bill-to Customer No.");
                    if not Customer.get(pSalesHeader."Sell-to Customer No.") then
                        Customer.Init();

                    SalesLine.VALIDATE("VAT Bus. Posting Group", Customer."VAT Bus. Posting Group");
                    SalesLine.VALIDATE("Gen. Bus. Posting Group", Customer."Gen. Bus. Posting Group");
                    SalesLine.VALIDATE("Gen. Prod. Posting Group", 'FG');
                    SalesLine.VALIDATE("VAT Prod. Posting Group", Item1."VAT Prod. Posting Group");
                    SalesLine.VALIDATE("Unit Price", TempSalesLine."Unit Price");
                    if TempSalesLine."Line Discount Amount" <> 0 then
                        SalesLine.VALIDATE("Line Discount Amount", TempSalesLine."Line Discount Amount");

                    SalesLine.VALIDATE("Location Code", TempSalesLine."Location Code");
                    //SalesLine.VALIDATE("Qty. to Asm. to Order (Base)", TempSalesLine."Qty. to Asm. to Order (Base)");
                    SalesLine."BPC.Interface" := TRUE;
                    SalesLine."BPC.Active" := TRUE;
                    SalesLine.MODIFY();
                END ELSE BEGIN
                    //SalesLine."No." := TempSalesLine."No.";
                    SalesLine."Unit of Measure Code" := TempSalesLine."Unit of Measure Code";
                    if not Item1.get(SalesLine."No.") then
                        Item1.Init();
                    // SalesLine."Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(Item1, TempSalesLine."Unit of Measure Code");
                    SalesLine."BPC.Not Check AutoAsmToOrder" := TempSalesLine."BPC.Not Check AutoAsmToOrder";
                    SalesLine.VALIDATE(Description, TempSalesLine.Description);
                    SalesLine."Qty. to Assemble to Order" := TempSalesLine."Qty. to Assemble to Order";
                    SalesLine."Qty. to Asm. to Order (Base)" := TempSalesLine."Qty. to Asm. to Order (Base)";
                    SalesLine.VALIDATE(Quantity, TempSalesLine.Quantity);
                    SalesLine.VALIDATE("Unit Price", TempSalesLine."Unit Price");
                    if TempSalesLine."Line Discount Amount" <> 0 then
                        SalesLine.VALIDATE("Line Discount Amount", TempSalesLine."Line Discount Amount");

                    if not Customer.get(pSalesHeader."Sell-to Customer No.") then
                        Customer.Init();
                    if (Customer."Gen. Bus. Posting Group" <> '') and (Customer."VAT Bus. Posting Group" <> '') then begin
                        SalesLine.VALIDATE("Sell-to Customer No.", pSalesHeader."Sell-to Customer No.");
                        SalesLine.VALIDATE("Bill-to Customer No.", pSalesHeader."Bill-to Customer No.");
                    end;

                    if SalesLine."VAT Bus. Posting Group" = '' then
                        SalesLine.VALIDATE("VAT Bus. Posting Group", Customer."VAT Bus. Posting Group");
                    if SalesLine."Gen. Bus. Posting Group" = '' then
                        SalesLine.VALIDATE("Gen. Bus. Posting Group", Customer."Gen. Bus. Posting Group");
                    if SalesLine."Gen. Prod. Posting Group" = '' then
                        SalesLine.VALIDATE("Gen. Prod. Posting Group", 'FG');
                    if SalesLine."VAT Prod. Posting Group" = '' then
                        SalesLine.VALIDATE("VAT Prod. Posting Group", Item1."VAT Prod. Posting Group");
                    SalesLine."Location Code" := TempSalesLine."Location Code";
                    //SalesLine.VALIDATE("Qty. to Asm. to Order (Base)", TempSalesLine."Qty. to Asm. to Order (Base)");
                    SalesLine."BPC.Interface" := TRUE;
                    SalesLine."BPC.Active" := TRUE;
                    SalesLine.MODIFY();
                END;

            UNTIL TempSalesLine.NEXT = 0;
            // CalcDiscByType.ApplyInvDiscBasedOnAmt(pSalesHeader."Invoice Discount Value", pSalesHeader)
            DeleteSalesLine.RESET;
            DeleteSalesLine.SETRANGE("Document Type", TempSalesLine."Document Type");
            DeleteSalesLine.SETRANGE("Document No.", TempSalesLine."Document No.");
            DeleteSalesLine.SETRANGE("BPC.Active", FALSE);
            IF DeleteSalesLine.FINDSET THEN
                DeleteSalesLine.DELETEALL();
        END;
        exit(true);
        // Window.CLOSE;
        //COMMIT;
    END;

    local procedure GenFullTaxNo(TransactionHeader: Record "LSC Transaction Header") FullTaxNo: Code[20]
    var
        Store: Record "LSC Store";
        TransH: Record "LSC Transaction Header";
        NoSeriesMgt: Codeunit NoSeriesManagement;
    begin
        Store.GET(TransactionHeader."Store No.");
        Store.TESTFIELD("BPC.Full VAT Nos.");
        IF TransH.GET(TransactionHeader."Store No.", TransactionHeader."POS Terminal No.", TransactionHeader."Transaction No.") THEN BEGIN
            TransH."BPC.Full Tax No." := NoSeriesMgt.GetNextNo(Store."BPC.Full VAT Nos.", TransactionHeader.Date, TRUE);
            TransH."BPC.Mark Full VAT" := TRUE;
            TransH.MODIFY;
            exit(TransH."BPC.Full Tax No.")
        END;

    end;

    var
        ReleasePurchDoc: Codeunit "Release Purchase Document";
        ReleaseSaleshDoc: Codeunit "Release Sales Document";
        JSONMgt: Codeunit "JSON Management";
        JsonUtil: Codeunit "LSC POS JSON Util";
        EposCtrl: Codeunit "LSC POS Control Interface";
        BOUtils: Codeunit "LSC BO Utils";
        JObjectData: JsonObject;
        JArrayData: JsonArray;
        JToken: JsonToken;
        Convert: Codeunit "Base64 Convert";
        RetailSetup: Record "LSC Retail Setup";
        APIConfiguration: Record "BPC.API Configuration";
        StoreInventoryWorksheet: Record "LSC Store Inventory Worksheet";
        StoreInventoryLine: Record "LSC Store Inventory Line";
        PostedStoreInventoryLine: Record "BPC.Posted Store InventoryLine";
        Vend: Record Vendor;
        PurchSetup: Record "Purchases & Payables Setup";
        SaleshSetup: Record "Sales & Receivables Setup";
        Store: Record "LSC Store";
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
        InterfaceData: Codeunit "BPC.Interface Data";
        TmpItemLedgerEntry: Record "Item Ledger Entry" temporary;

        TempSalesHeader: Record "Sales Header" temporary;
        TempItem: Record Item temporary;
        TempSalesLine: Record "Sales Line" temporary;
        TempSalesLine1: Record "Sales Line" temporary;

}