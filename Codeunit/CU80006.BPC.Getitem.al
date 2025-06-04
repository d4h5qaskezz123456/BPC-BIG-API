codeunit 80006 "BPC.Getitem"
{
    trigger OnRun()
    var
        myInt: Integer;
    begin
        GetItem(true);
    end;

    procedure GetItem(JobGetItem: Boolean)
    var
        RetailUser: Record "LSC Retail User";
        StoreLocation: Record "LSC Store Location";
        SalesHeader: Record "Sales Header";
        fromDate: Text;
        fromTime: Text;
        toDate: Text;
        toTime: Text;
        StarDate: Text;
        EndDate: Text;
        BPIConfiguration: Record "BPC.API Configuration";
        Item: Record Item;
        toDateTiem: Text;
        fromDateTiem: Text;
    begin
        CLEAR(JsonRequestStr);
        CLEAR(APIResult);
        CheckConfigInterface();

        //IF RetailUser.GET(USERID) THEN BEGIN
        // StoreLocation.RESET;
        // StoreLocation.SETRANGE("Store No.", RetailUser."Store No.");
        Clear(fromDate);
        Clear(toDate);
        Clear(fromDateTiem);
        Clear(toDateTiem);
        // IF StoreLocation.FINDSET THEN BEGIN
        //     REPEAT
        //         IF StoreLocation."Location Code" <> '' THEN BEGIN
        FunctionsName := 'GetItem';
        DocumentNo := '';
        if not JobGetItem then begin
            BPIConfiguration.get;
            fromDate := FORMAT(BPIConfiguration.StarDate, 0, '<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>Z');
            toDate := FORMAT(BPIConfiguration.EndDate, 0, '<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>Z');
            JsonRequestStr := STRSUBSTNO('{company:"%1",fromDateTime:"%2",toDateTime:"%3"}', Company_Name, fromDate, toDate);
        end else begin
            // Item.Reset();
            // Item.SetCurrentKey("BPC.Modified date and time");
            // Item.SetFilter("No.", '<>%1', '');
            // if Item.FindLast() then begin
            //     // fromDate := FORMAT(Item."BPC.Modified date and time", 0, '<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>Z');
            //     fromDate := Format(Today, 0, '<Year4>-<Month,2>-<Day,2>');
            //     fromTime := Format(Time - (1 * 3600000), 0, '<Hours24,2>:<Minutes,2>:<Seconds,2>');
            //     fromDateTiem := StrSubstNo('%1T%2Z', fromDate, fromTime);

            //     toDate := Format(Today, 0, '<Year4>-<Month,2>-<Day,2>');
            //     toTime := Format(Time, 0, '<Hours24,2>:<Minutes,2>:<Seconds,2>');
            //     toDateTiem := StrSubstNo('%1T%2Z', toDate, toTime);
            // end;
            // JsonRequestStr := STRSUBSTNO('{company:"%1",fromDateTime:"%2",toDateTime:"%3"}', Company_Name, fromDateTiem, toDateTiem);
            JsonRequestStr := STRSUBSTNO('{company:"%1"}', Company_Name);
        end;


        //JsonRequestStr := STRSUBSTNO('{company:"%1",fromDateTime:"2023-08-28T00:00:00Z",toDateTime:"2023-08-28T13:23:00Z"}', Company_Name);
        if InterfaceData.CallAPIService_POST(FunctionsName, JsonRequestStr, APIResult, DocumentNo) THEN BEGIN
            GenerateTempItem(TRUE, APIResult);
            InsertItem(TRUE, RetailUser."Store No.", StoreLocation."Location Code");
            Message('Success.');
        END else
            Message(GetLastErrorText());
        //         END;
        //     UNTIL StoreLocation.NEXT = 0;
        // END;
    END;
    // end;

    local procedure GenerateTempItem(IsGenHeader: Boolean; APIResult: Text)
    var
        StoreLocation: Record "LSC Store Location";
        ItemVariantRegistration: Record "LSC Item Variant Registration";
        MinusQtyFound: Boolean;
        PType: Text;
        ItemModelGroup: Text;
        ItemCategory: Record "Item Category";
        ItemCategoryCode: Code[20];
        RetailProGroup: Record "LSC Retail Product Group";
        RetailProductCode: Code[20];
        JSUnitConArray: JsonArray;
        JUnitCon: JsonToken;
        JUnitConOJ: JsonObject;
        JTypeToken: JsonToken;
        UnitofMeasure: Record "Unit of Measure";
        ItemUnitofMeasure: Record "Item Unit of Measure";
        ItemUnitofMeasure1: Record "Item Unit of Measure";
        ItemUnitofMeasureCode: Code[20];
        ItemStatusLink: Record "LSC Item Status Link";
        InventoryStoped: Boolean;
        PurchaseStoped: Boolean;
        SaleStoped: Boolean;
        InventoryPostingGroup: Record "Inventory Posting Group";
        ItemTrackingCode: Record "Item Tracking Code";
        ItemTracCode: Code[20];
        ItemCate: Record "Item Category";
        toUnit: Code[20];
        factor: Decimal;
        BaseUnitofMeasure: Code[20];
        InventoryUnitDesc: Text;
        PurchaseUnitDesc: Text;
        SaleUnitDesc: Text;
    begin
        TempItem.DELETEALL;
        MinusQtyFound := FALSE;
        CLEAR(JObjectData);
        CLEAR(JArrayData);

        Window.OPEN('Generate Item No. #1############################');
        // Error(APIResult);
        //JObjectData.WriteTo(APIResult);
        JArrayData.ReadFrom(APIResult);

        FOREACH JToken IN JArrayData DO BEGIN
            JObjectData := JToken.AsObject();
            IF IsGenHeader THEN BEGIN
                CLEAR(ItemUnitofMeasureCode);
                CLEAR(JTypeToken);
                CLEAR(JUnitConOJ);
                CLEAR(JUnitCon);
                CLEAR(JSUnitConArray);
                CLEAR(RetailProductCode);
                CLEAR(ItemCategoryCode);
                CLEAR(PType);
                Clear(ItemTracCode);
                CLEAR(toUnit);
                Clear(factor);
                Clear(ItemModelGroup);
                Clear(BaseUnitofMeasure);
                Clear(InventoryUnitDesc);
                Clear(SaleUnitDesc);
                Clear(PurchaseUnitDesc);
                InventoryStoped := FALSE;
                PurchaseStoped := FALSE;
                SaleStoped := FALSE;
                TempItem.INIT;
                // if JObjectData.get('ItemId', JToken) then
                //     WindowUPDATE := JToken.AsValue().AsInteger();

                // Window.UPDATE(1, WindowUPDATE);

                if JObjectData.get('ItemId', JToken) then
                    TempItem."No." := JToken.AsValue().AsCode();
                if JObjectData.get('ProductType', JToken) then begin
                    PType := JToken.AsValue().AsText();
                    if PType <> '' then begin
                        if PType = 'Item' then
                            TempItem.Type := TempItem.Type::Inventory;
                        if PType = 'Service' then begin
                            TempItem.Type := TempItem.Type::Service;
                            TempItem."Gen. Prod. Posting Group" := 'SERVICE';
                        end else begin
                            TempItem."Gen. Prod. Posting Group" := 'FG';
                        end;
                    end else begin
                        TempItem."Gen. Prod. Posting Group" := 'FG';
                    end;
                end;
                if JObjectData.get('Productname', JToken) then begin
                    //Suea
                    ProductName := JToken.AsValue().AsText();
                    TempItem.Description := CopyStr(ProductName, 1, 100);
                    TempItem."Description 2" := CopyStr(ProductName, 101, 50);
                    //Suea
                end;

                if JObjectData.get('Searchname', JToken) then
                    TempItem."Search Description" := JToken.AsValue().AsCode();

                InventoryPostingGroup.Reset();
                InventoryPostingGroup.SetRange(Code, 'FG');
                if not InventoryPostingGroup.FindSet() then begin
                    InventoryPostingGroup.Init();
                    InventoryPostingGroup.Code := 'FG';
                    InventoryPostingGroup.Insert();
                end;

                TempItem."Inventory Posting Group" := 'FG';
                if JObjectData.get('ItemModelGroup', JToken) then begin
                    ItemModelGroup := JToken.AsValue().AsText();
                    if ItemModelGroup <> '' then begin
                        if ItemModelGroup = 'FIFO' then
                            TempItem."Costing Method" := TempItem."Costing Method"::FIFO;
                        if ItemModelGroup = 'Average' then
                            TempItem."Costing Method" := TempItem."Costing Method"::Average;
                    end;
                end;
                if JObjectData.get('TrackingDimensionGroup', JToken) then
                    ItemTracCode := JToken.AsValue().AsCode();
                if ItemTracCode <> '' then begin
                    ItemTrackingCode.Reset();
                    ItemTrackingCode.SetRange(Code, ItemTracCode);
                    if not ItemTrackingCode.FindSet() then begin
                        ItemTrackingCode.Init();
                        ItemTrackingCode.Code := ItemTracCode;
                        ItemTrackingCode.Insert();
                    end;
                end;
                TempItem."Item Tracking Code" := ItemTracCode;
                if JObjectData.get('PurchaseUnit', JToken) then
                    TempItem."Purch. Unit of Measure" := JToken.AsValue().AsCode();

                if JObjectData.get('PurchaseUnitDesc', JToken) then
                    PurchaseUnitDesc := JToken.AsValue().AsText();

                if TempItem."Purch. Unit of Measure" <> '' then
                    InsertUnitofMeasure(TempItem."Purch. Unit of Measure", PurchaseUnitDesc);


                if JObjectData.get('SaleUnit', JToken) then
                    TempItem."Sales Unit of Measure" := JToken.AsValue().AsCode();

                if JObjectData.get('SaleUnitDesc', JToken) then
                    SaleUnitDesc := JToken.AsValue().AsText();

                if TempItem."Sales Unit of Measure" <> '' then
                    InsertUnitofMeasure(TempItem."Sales Unit of Measure", SaleUnitDesc);


                if JObjectData.get('InventoryUnit', JToken) then begin
                    BaseUnitofMeasure := JToken.AsValue().AsCode();
                    if BaseUnitofMeasure <> '' then begin
                        ItemUnitofMeasure.Reset();
                        if not ItemUnitofMeasure.Get(TempItem."No.", BaseUnitofMeasure) then begin
                            ItemUnitofMeasure.Init();
                            ItemUnitofMeasure.Code := BaseUnitofMeasure;
                            ItemUnitofMeasure."Item No." := TempItem."No.";
                            ItemUnitofMeasure."Qty. per Unit of Measure" := 1;
                            ItemUnitofMeasure.Insert();
                        end else begin
                            // ItemUnitofMeasure.Validate("Item No.", TempItem."No.");
                            ItemUnitofMeasure."Qty. per Unit of Measure" := 1;
                            ItemUnitofMeasure.Modify();
                        end;
                    end;
                    TempItem."Base Unit of Measure" := BaseUnitofMeasure;
                end;

                if JObjectData.get('InventoryUnitDesc', JToken) then begin
                    InventoryUnitDesc := JToken.AsValue().AsText();
                end;
                if BaseUnitofMeasure <> '' then
                    InsertUnitofMeasure(BaseUnitofMeasure, InventoryUnitDesc);

                if JObjectData.get('Brand', JToken) then
                    TempItem."BPC.Brand" := JToken.AsValue().AsCode();
                if JObjectData.get('Brand_Des', JToken) then
                    TempItem."BPC.Brand Description" := JToken.AsValue().AsText();

                if JObjectData.get('ItemGroupId', JToken) then begin
                    ItemCategoryCode := JToken.AsValue().AsCode();
                    if ItemCategoryCode <> '' then
                        if not ItemCategory.Get(ItemCategoryCode) then begin
                            ItemCategory.Init();
                            ItemCategory.Code := ItemCategoryCode;
                            ItemCategory."LSC POS Inventory Lookup" := true; // Joe 2025-03-14
                            ItemCategory.Insert();
                            TempItem."Item Category Code" := ItemCategoryCode;
                            TempItem.Description := ItemCategoryCode;
                        end else begin
                            TempItem."Item Category Code" := ItemCategoryCode;
                            ItemCategory.Description := ItemCategoryCode;
                            ItemCategory.Modify()
                        end;
                end;

                if JObjectData.get('SubcategoryValue', JToken) then begin
                    RetailProductCode := JToken.AsValue().AsCode();
                    if RetailProductCode <> '' then begin
                        RetailProGroup.Reset();
                        RetailProGroup.SetRange("Item Category Code", ItemCategoryCode);
                        RetailProGroup.SetRange(Code, RetailProductCode);
                        if not RetailProGroup.FindSet() then begin
                            RetailProGroup.Init();
                            RetailProGroup."Item Category Code" := ItemCategoryCode;
                            RetailProGroup.Code := RetailProductCode;
                            RetailProGroup.Description := RetailProductCode;
                            RetailProGroup."POS Inventory Lookup" := true; // Joe 2025-03-14
                            RetailProGroup.Insert();
                        end else begin
                            RetailProGroup.Description := RetailProductCode;
                            RetailProGroup.Modify();
                        end;
                    end;
                    TempItem."LSC Retail Product Code" := RetailProductCode;
                end;

                //UnitConversion
                if JObjectData.get('UnitConversion', JToken) then begin
                    JSUnitConArray := JToken.AsArray();
                    foreach JUnitCon in JSUnitConArray do begin
                        JUnitConOJ := JUnitCon.AsObject();
                        if JUnitConOJ.Get('factor', JTypeToken) then
                            factor := JTypeToken.AsValue().AsDecimal();

                        if factor > 0 then begin
                            if JUnitConOJ.Get('fromUnit', JTypeToken) then
                                ItemUnitofMeasureCode := JTypeToken.AsValue().AsCode();
                            if ItemUnitofMeasureCode <> '' then begin
                                UnitofMeasure.Reset();
                                UnitofMeasure.SetRange(Code, ItemUnitofMeasureCode);
                                if not UnitofMeasure.FindSet() then begin
                                    UnitofMeasure.Init();
                                    UnitofMeasure.Code := ItemUnitofMeasureCode;
                                    UnitofMeasure.Insert();
                                end;
                                ItemUnitofMeasure.Reset();
                                ItemUnitofMeasure.SetRange("Item No.", TempItem."No.");
                                ItemUnitofMeasure.SetRange(Code, ItemUnitofMeasureCode);
                                if not ItemUnitofMeasure.FindSet() then begin
                                    ItemUnitofMeasure.Init();
                                    ItemUnitofMeasure.Code := ItemUnitofMeasureCode;
                                    ItemUnitofMeasure."Item No." := TempItem."No.";
                                    ItemUnitofMeasure."Qty. per Unit of Measure" := factor;
                                    ItemUnitofMeasure.Insert();
                                end else begin
                                    ItemUnitofMeasure.Init();
                                    //     ItemUnitofMeasure.Validate("Item No.", TempItem."No.");
                                    ItemUnitofMeasure."Qty. per Unit of Measure" := factor;
                                    ItemUnitofMeasure.Modify();
                                end;

                                if JUnitConOJ.Get('toUnit', JTypeToken) then begin
                                    toUnit := JTypeToken.AsValue().AsCode();
                                    if toUnit <> '' then begin
                                        UnitofMeasure.Reset();
                                        if not UnitofMeasure.Get(toUnit) then begin
                                            UnitofMeasure.Init();
                                            UnitofMeasure.Code := toUnit;
                                            UnitofMeasure.Insert();
                                        end;
                                        ItemUnitofMeasure1.Reset();
                                        if not ItemUnitofMeasure1.Get(TempItem."No.", toUnit) then begin
                                            ItemUnitofMeasure1.Init();
                                            ItemUnitofMeasure1.Code := toUnit;
                                            ItemUnitofMeasure1."Item No." := TempItem."No.";
                                            ItemUnitofMeasure1."Qty. per Unit of Measure" := 1;
                                            ItemUnitofMeasure1.Insert();
                                        end else begin
                                            ItemUnitofMeasure1.Init();
                                            //     ItemUnitofMeasure1.Validate("Item No.", TempItem."No.");
                                            ItemUnitofMeasure1."Qty. per Unit of Measure" := 1;
                                            ItemUnitofMeasure1.Modify();
                                        end;
                                    end;
                                end;
                            end;
                        end;
                    end;
                end;

                if JObjectData.get('SaleTaxGroup', JToken) then
                    TempItem."VAT Prod. Posting Group" := JToken.AsValue().AsCode();
                if JObjectData.get('Model', JToken) then
                    TempItem."BPC.Model" := JToken.AsValue().AsCode();
                if JObjectData.get('Model_Des', JToken) then
                    TempItem."BPC.Model Description" := JToken.AsValue().AsText();
                if JObjectData.get('Type', JToken) then
                    TempItem."BPC.Type" := JToken.AsValue().AsCode();
                if JObjectData.get('Type_Des', JToken) then
                    TempItem."BPC.Type Description" := JToken.AsValue().AsText();
                if JObjectData.get('Size', JToken) then
                    TempItem."BPC.Size" := JToken.AsValue().AsCode();
                if JObjectData.get('Size_Des', JToken) then
                    TempItem."BPC.Size Description" := JToken.AsValue().AsText();
                if JObjectData.get('Type1', JToken) then
                    TempItem."BPC.Type 1" := JToken.AsValue().AsCode();
                if JObjectData.get('Type1_Des', JToken) then
                    TempItem."BPC.Type1 Description" := JToken.AsValue().AsText();
                if JObjectData.get('Type2', JToken) then
                    TempItem."BPC.Type 2" := JToken.AsValue().AsCode();
                if JObjectData.get('Type2_Des', JToken) then
                    TempItem."BPC.Type2 Description" := JToken.AsValue().AsText();
                if JObjectData.get('Modified', JToken) then
                    TempItem."Last Date Modified" := JToken.AsValue().AsDate();

                if JObjectData.get('InventoryStoped', JToken) then
                    InventoryStoped := JToken.AsValue().AsBoolean();

                TempItem."BPC.Inventory Stoped" := InventoryStoped;

                if JObjectData.get('PurchaseStoped', JToken) then
                    PurchaseStoped := JToken.AsValue().AsBoolean();

                TempItem."BPC.Purchase Stoped" := PurchaseStoped;

                if JObjectData.get('Sale Stoped', JToken) then
                    SaleStoped := JToken.AsValue().AsBoolean();

                TempItem."BPC.Sale Stoped" := SaleStoped;
                TempItem."Price Includes VAT" := true;

                if SaleStoped or PurchaseStoped or InventoryStoped then begin
                    ItemStatusLink.Reset();
                    ItemStatusLink.SetRange("Item No.", TempItem."No.");
                    if not ItemStatusLink.FindSet() then begin
                        ItemStatusLink.Init();
                        ItemStatusLink."Item No." := TempItem."No.";
                        if SaleStoped then begin
                            ItemStatusLink."Block Sale on POS" := true;
                            ItemStatusLink."Block Sale in Sales Order" := true;
                            ItemStatusLink."Block Sales Return" := true;
                        end;
                        if PurchaseStoped then begin
                            ItemStatusLink."Block Purchasing" := true;
                            ItemStatusLink."Block Purchase Return" := true;
                        end;
                        if InventoryStoped then begin
                            ItemStatusLink."Block Transferring" := true;
                            ItemStatusLink."Block Negative Adjustment" := true;
                            ItemStatusLink."Block Positive Adjustment" := true;
                        end;
                        ItemStatusLink.Insert();
                    end else begin
                        if SaleStoped then begin
                            ItemStatusLink."Block Sale on POS" := true;
                            ItemStatusLink."Block Sale in Sales Order" := true;
                            ItemStatusLink."Block Sales Return" := true;
                        end;
                        if PurchaseStoped then begin
                            ItemStatusLink."Block Purchasing" := true;
                            ItemStatusLink."Block Purchase Return" := true;
                        end;
                        if InventoryStoped then begin
                            ItemStatusLink."Block Transferring" := true;
                            ItemStatusLink."Block Negative Adjustment" := true;
                            ItemStatusLink."Block Positive Adjustment" := true;
                        end;
                        ItemStatusLink.Modify();
                    end;
                end;
                if not SaleStoped or not PurchaseStoped or not InventoryStoped then begin
                    ItemStatusLink.Reset();
                    ItemStatusLink.SetRange("Item No.", TempItem."No.");
                    if not ItemStatusLink.FindSet() then begin
                        ItemStatusLink.Init();
                        ItemStatusLink."Item No." := TempItem."No.";
                        if not SaleStoped then begin
                            ItemStatusLink."Block Sale on POS" := false;
                            ItemStatusLink."Block Sale in Sales Order" := false;
                            ItemStatusLink."Block Sales Return" := false;
                        end;
                        if not PurchaseStoped then begin
                            ItemStatusLink."Block Purchasing" := false;
                            ItemStatusLink."Block Purchase Return" := false;
                        end;
                        if not InventoryStoped then begin
                            ItemStatusLink."Block Transferring" := false;
                            ItemStatusLink."Block Negative Adjustment" := false;
                            ItemStatusLink."Block Positive Adjustment" := false;
                        end;
                        ItemStatusLink.Insert();
                    end else begin
                        if not SaleStoped then begin
                            ItemStatusLink."Block Sale on POS" := false;
                            ItemStatusLink."Block Sale in Sales Order" := false;
                            ItemStatusLink."Block Sales Return" := false;
                        end;
                        if not PurchaseStoped then begin
                            ItemStatusLink."Block Purchasing" := false;
                            ItemStatusLink."Block Purchase Return" := false;
                        end;
                        if not InventoryStoped then begin
                            ItemStatusLink."Block Transferring" := false;
                            ItemStatusLink."Block Negative Adjustment" := false;
                            ItemStatusLink."Block Positive Adjustment" := false;
                        end;
                        ItemStatusLink.Modify();
                    end;
                end;

                if JObjectData.get('ModifiedDate', JToken) then begin
                    TempItem."BPC.Modified date and time" := JToken.AsValue().AsDateTime();
                END;

                TempItem.INSERT;
            END;
        END;
        Window.CLOSE;
    end;

    local procedure InsertItem(IsGenHeader: Boolean; pStoreNo: Code[10]; pLocCode: Code[10])
    var
        SalesHeader: Record "sales Header";
        SalesLine: Record "sales Line";
        Item: Record Item;
        DataInsert: Boolean;
        Status_Var: Option Open,Released,"Pending Approval","Pending Prepayment";

        InterfaceDocumentStatus: Record "BPC.Interface Document Status";
    begin
        Window.OPEN('Insert Item No. #1############################');
        IF IsGenHeader THEN BEGIN
            TempItem.RESET;
            TempItem.SetFilter(TempItem."No.", '<>%1', '');
            IF TempItem.FINDSET THEN BEGIN
                REPEAT
                    Window.UPDATE(1, TempItem."No.");
                    Item.RESET;
                    Item.SETRANGE("No.", TempItem."No.");
                    IF NOT Item.FindSet() THEN BEGIN
                        // INSERT
                        Item.INIT;
                        Item.TRANSFERFIELDS(TempItem);
                        Item."VAT Bus. Posting Gr. (Price)" := 'DOMESTIC';
                        Item."VAT Prod. Posting Group" := TempItem."VAT Prod. Posting Group";
                        Item."LSC Retail Product Code" := TempItem."LSC Retail Product Code";
                        Item.Insert();
                        // Item.VALIDATE(Type, TempItem.Type);
                        // Item.VALIDATE(Description, TempItem.Description);
                        // Item.VALIDATE("Search Description", TempItem."Search Description");
                        // //Item.VALIDATE("Inventory Posting Group", TempItem."Inventory Posting Group");
                        // Item.VALIDATE("Costing Method", TempItem."Costing Method");
                        // // Item.VALIDATE("Purch. Unit of Measure", TempItem."Purch. Unit of Measure");
                        // //Item.VALIDATE("Item Tracking Code", TempItem."Item Tracking Code");
                        // //Item.VALIDATE("Sales Unit of Measure", TempItem."Sales Unit of Measure");
                        // Item.VALIDATE("Base Unit of Measure", TempItem."Base Unit of Measure");
                        // Item.VALIDATE("BPC.Brand", TempItem."BPC.Brand");
                        // Item.VALIDATE("BPC.Brand Description", TempItem."BPC.Brand Description");
                        // Item.VALIDATE("Item Category Code", TempItem."Item Category Code");
                        // Item.VALIDATE("LSC Retail Product Code", TempItem."LSC Retail Product Code");
                        // Item.VALIDATE("Last Date Modified", TempItem."Last Date Modified");
                        // Item.VALIDATE("bpc.Model", TempItem."bpc.Model");
                        // Item.VALIDATE("BPC.Model Description", TempItem."BPC.Model Description");
                        // Item.VALIDATE("bpc.type", TempItem."bpc.type");
                        // Item.VALIDATE("BPC.Type Description", TempItem."BPC.Type Description");
                        // Item.VALIDATE("bpc.type 1", TempItem."bpc.type 1");
                        // Item.VALIDATE("BPC.Type1 Description", TempItem."BPC.Type1 Description");
                        // Item.VALIDATE("bpc.type 2", TempItem."bpc.type 2");
                        // Item.VALIDATE("BPC.Type2 Description", TempItem."BPC.Type2 Description");
                        // Item.VALIDATE("BPC.Size", TempItem."BPC.Size");
                        // Item.VALIDATE("BPC.Size Description", TempItem."BPC.Size Description");
                        // Item.MODIFY();
                    END ELSE BEGIN
                        // MODIFY
                        //--A-- 2024/11/15 ++
                        if not Item."BPC.Block Update Type" then
                            Item.Type := TempItem.Type;
                        //--A-- 2024/11/15 --

                        Item."Search Description" := TempItem."Search Description";
                        Item."BPC.Brand" := TempItem."BPC.Brand";
                        Item."BPC.Brand Description" := TempItem."BPC.Brand Description";
                        Item."Item Category Code" := TempItem."Item Category Code";
                        Item."LSC Retail Product Code" := TempItem."LSC Retail Product Code";
                        Item."Costing Method" := TempItem."Costing Method";
                        Item."Inventory Posting Group" := TempItem."Inventory Posting Group";
                        Item."Gen. Prod. Posting Group" := TempItem."Gen. Prod. Posting Group";
                        Item."Purch. Unit of Measure" := TempItem."Purch. Unit of Measure";
                        Item."Item Tracking Code" := TempItem."Item Tracking Code";
                        Item."Sales Unit of Measure" := TempItem."Sales Unit of Measure";
                        Item."Base Unit of Measure" := TempItem."Base Unit of Measure";
                        Item.Description := TempItem.Description;

                        //Suea
                        Item."Description 2" := TempItem."Description 2";
                        Item."VAT Bus. Posting Gr. (Price)" := 'DOMESTIC';
                        //Suea 

                        Item."Last Date Modified" := TempItem."Last Date Modified";
                        Item."bpc.Model" := TempItem."bpc.Model";
                        Item."BPC.Model Description" := TempItem."BPC.Model Description";
                        Item."bpc.type" := TempItem."bpc.type";
                        Item."BPC.Type Description" := TempItem."BPC.Type Description";
                        Item."bpc.type 1" := TempItem."bpc.type 1";
                        Item."BPC.Type1 Description" := TempItem."BPC.Type1 Description";
                        Item."bpc.type 2" := TempItem."bpc.type 2";
                        Item."BPC.Type2 Description" := TempItem."BPC.Type2 Description";
                        Item."BPC.Size" := TempItem."BPC.Size";
                        Item."BPC.Size Description" := TempItem."BPC.Size Description";
                        Item."BPC.Modified date and time" := TempItem."BPC.Modified date and time";
                        Item."BPC.Inventory Stoped" := TempItem."BPC.Inventory Stoped";
                        Item."BPC.Purchase Stoped" := TempItem."BPC.Purchase Stoped";
                        Item."BPC.Sale Stoped" := TempItem."BPC.Sale Stoped";
                        Item."VAT Prod. Posting Group" := TempItem."VAT Prod. Posting Group";
                        Item."Price Includes VAT" := true;
                        Item.MODIFY();
                    END;
                UNTIL TempItem.NEXT = 0;
            END;
        END;
        Window.CLOSE;
        COMMIT;
    end;

    procedure InsertUnitofMeasure(Code: Text; Description: Text)
    var
        UnitofMeasure: Record "Unit of Measure";
    begin
        UnitofMeasure.Reset();
        UnitofMeasure.SetRange(Code, Code);
        if not UnitofMeasure.FindSet() then begin
            UnitofMeasure.Init();
            UnitofMeasure.Code := Code;
            UnitofMeasure.Description := Description;
            UnitofMeasure.Insert();
        end else begin
            UnitofMeasure.Description := Description;
            UnitofMeasure.Modify();
        end;
    end;

    procedure CheckConfigInterface()
    begin
        RetailSetup.GET();
        IF NOT RetailSetup."BPC.Interface D365 Active" THEN
            ERROR('Interface D365 Active for Retail Setup not Active');
        IF RetailSetup."BPC.Interface Tenant ID" = '' THEN BEGIN
            IF RetailSetup."BPC.Interface User Name" = '' THEN
                ERROR('Interface User Name for Retail Setup not found');
            IF RetailSetup."BPC.Interface Password" = '' THEN
                ERROR('Interface Password for Retail Setup not found');
        END;
        IF RetailSetup."BPC.Interface ClientID" = '' THEN
            ERROR('Interface ClientID for Retail Setup not found');
        IF RetailSetup."BPC.Interface Client Secret" = '' THEN
            ERROR('Interface Client Secret for Retail Setup not found');
        IF RetailSetup."BPC.Interface Resource" = '' THEN
            ERROR('Interface Resource for Retail Setup not found');
        IF RetailSetup."BPC.Interface Company" = '' THEN
            ERROR('Interface Company for Retail Setup not found');

        Company_Name := RetailSetup."BPC.Interface Company";
    end;

    var
        WindowUPDATE: Integer;
        Window: Dialog;
        TempItem: Record Item temporary;
        JObjectData: JsonObject;
        JArrayData: JsonArray;
        JToken: JsonToken;
        InterfaceData: Codeunit "BPC.Interface Data";
        FunctionsName: Text;
        Company_Name: Text;
        RetailSetup: Record "LSC Retail Setup";
        JsonRequestStr: Text;
        APIResult: Text;
        DocumentNo: Text;
        ProductName: Text;
}