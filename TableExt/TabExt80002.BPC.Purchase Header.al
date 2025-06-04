tableextension 80002 "BPC Purchase Header" extends "Purchase Header"
{
    fields
    {
        field(80100; "BPC.Tax Invoice Amount"; Decimal)
        {
            Caption = 'Tax Invoice Amount';
            DataClassification = ToBeClassified;
            Description = 'LCBC1.0';
        }
        field(80101; "BPC.Tax Invoice Date"; Date)
        {
            Caption = 'Tax Invoice Date';
            DataClassification = ToBeClassified;
            Description = 'LCBC1.0';
        }
        field(80102; "BPC.Temp. Applies-to ID"; Code[50])
        {
            Caption = 'Temp. Applies-to ID';
            DataClassification = ToBeClassified;
            Description = 'LCBC1.0 : Reserve Field ID for Posted.';
            Enabled = false;

            trigger OnValidate()
            var
                TempCustLedgEntry: Record "Cust. Ledger Entry";
            begin
            end;
        }
        field(80103; "BPC.Buy-from Vendor Name 3"; Text[50])
        {
            Caption = 'Buy-from Vendor Name 3';
            DataClassification = ToBeClassified;
            Description = 'LCBC1.0';
        }
        field(80104; "BPC.Pay-to Name 3"; Text[50])
        {
            Caption = 'Pay-to Name 3';
            DataClassification = ToBeClassified;
            Description = 'LCBC1.0';
        }
        field(80105; "BPC.Ship-to Name 3"; Text[50])
        {
            Caption = 'Ship-to Name 3';
            DataClassification = ToBeClassified;
            Description = 'LCBC1.0';
        }
        field(80106; "BPC.Buy-from Address 3"; Text[50])
        {
            Caption = 'Buy-from Address 3';
            DataClassification = ToBeClassified;
            Description = 'LCBC1.0';
        }
        field(80107; "BPC.Pay-to Address 3"; Text[50])
        {
            Caption = 'Pay-to Address 3';
            DataClassification = ToBeClassified;
            Description = 'LCBC1.0';
        }
        field(80108; "BPC.Ship-to Address 3"; Text[50])
        {
            Caption = 'Ship-to Address 3';
            DataClassification = ToBeClassified;
            Description = 'LCBC1.0';
        }
        field(80109; "BPC.Head Office Pay-to"; Boolean)
        {
            Caption = 'Head Office Pay-to';
            DataClassification = ToBeClassified;
            Description = 'LCBC1.0';

            trigger OnValidate()
            begin
                IF "BPC.Head Office Pay-to" THEN
                    TESTFIELD("BPC.Branch No. Pay-to", '');
            end;
        }
        field(80110; "BPC.Branch No. Pay-to"; Code[5])
        {
            Caption = 'Branch No. Pay-to';
            DataClassification = ToBeClassified;
            Description = 'LCBC1.0';

            trigger OnValidate()
            begin
                IF "BPC.Branch No. Pay-to" <> '' THEN
                    TESTFIELD("BPC.Head Office Pay-to", FALSE);
            end;
        }
        field(80111; "BPC.PO No. Series"; Code[10])
        {
            Caption = 'PO No. Series';
            DataClassification = ToBeClassified;
            Description = 'LCBC1.0';

            trigger OnLookup()
            begin
                PurchSetup.GET;
                PurchSetup.TESTFIELD("Order Nos.");
                IF NoSeriesMgt.LookupSeries(PurchSetup."Order Nos.", "BPC.PO No. Series") THEN
                    VALIDATE("BPC.PO No. Series");
            end;

            trigger OnValidate()
            begin
                IF "BPC.PO No. Series" <> '' THEN BEGIN
                    PurchSetup.GET;
                    PurchSetup.TESTFIELD("Order Nos.");
                    NoSeriesMgt.TestSeries(PurchSetup."Order Nos.", "BPC.PO No. Series");
                END;
            end;
        }
        field(80112; "BPC.Create from Requisition"; Boolean)
        {
            DataClassification = ToBeClassified;
            Description = 'LCBC1.0';
            Editable = false;
        }
        field(80113; "BPC.Req. Template"; Code[10])
        {
            DataClassification = ToBeClassified;
            Description = 'LCBC1.0';
            Editable = false;
        }
        field(80114; "BPC.Req. Wkst Name"; Code[10])
        {
            DataClassification = ToBeClassified;
            Description = 'LCBC1.0';
            Editable = false;
        }
        field(80115; "BPC.Total Discount %"; Decimal)
        {
            Caption = 'Total Discount %';
            DataClassification = ToBeClassified;
            DecimalPlaces = 0 : 5;
            Description = 'Ton 11/02/2020';
            MaxValue = 100;
            MinValue = 0;
        }
        field(80116; "BPC.Store Name"; Text[100])
        {
            CalcFormula = Lookup("LSC Store".Name WHERE("No." = field("LSC Store No.")));
            Caption = 'Store Name';
            FieldClass = FlowField;
            TableRelation = "LSC Store";

            trigger OnValidate()
            var
                lStores: Record "LSC Store";
            begin
                // LS -
                TESTFIELD(Status, Status::Open);

                "Location Code" := '';
                IF "LSC Store No." <> '' THEN
                    IF lStores.GET("LSC Store No.") THEN BEGIN
                        "Location Code" := lStores."Location Code";
                        VALIDATE("Shortcut Dimension 1 Code", lStores."Global Dimension 1 Code");
                    END;
                //LS +
            end;
        }
        field(80117; "BPC.Interface"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Interface';
        }
        field(80118; "BPC.Active"; Boolean)
        {
            Caption = 'Active';
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(80119; "BPC.Post at FO Status"; Boolean)
        {
            CalcFormula = Min("BPC.Interface Document Status"."BPC.Posted At FO" WHERE("BPC.Reference Document No." = FIELD("No.")));
            Editable = false;
            FieldClass = FlowField;
            Caption = 'Post at FO Status';

        }
        field(80120; "BPC.To D365"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'To D365';
        }
        field(80121; "BPC.Location Code"; Code[10])
        {
            DataClassification = ToBeClassified;
        }

    }
    procedure CheckLotExpDateOnReceipt()
    var
        CheckPurchLine: Record "Purchase Line";
        CheckPurchHeader: Record "Purchase Header";
        GenPostSetup: Record "General Posting Setup";
        VATPostSetup: Record "VAT Posting Setup";
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        InvPostSetup: Record "Inventory Posting Setup";
        ReservationEntry: Record "Reservation Entry";
        LotTracking: Boolean;
        SNTracking: Boolean;
        SumQtyHandle: Decimal;
    begin
        CheckPurchLine.RESET;
        CheckPurchLine.SETRANGE("Document Type", "Document Type");
        CheckPurchLine.SETRANGE("Document No.", "No.");
        IF CheckPurchLine.FINDSET THEN
            REPEAT
                IF NOT CheckPurchHeader.GET(CheckPurchLine."Document Type", CheckPurchLine."Document No.") THEN
                    CheckPurchHeader.INIT;
                CheckPurchHeader.TESTFIELD("LSC Store No.", CheckPurchHeader."Location Code");
                IF (CheckPurchLine."Qty. to Receive" <> 0) AND (CheckPurchLine.Type IN [CheckPurchLine.Type::Item]) THEN BEGIN
                    CheckPurchLine.TESTFIELD("Gen. Bus. Posting Group");
                    CheckPurchLine.TESTFIELD("Gen. Prod. Posting Group");
                    CheckPurchLine.TESTFIELD("VAT Bus. Posting Group");
                    CheckPurchLine.TESTFIELD("VAT Prod. Posting Group");
                    CheckPurchLine.TESTFIELD("Location Code", CheckPurchHeader."Location Code");
                    GenPostSetup.GET(CheckPurchLine."Gen. Bus. Posting Group", CheckPurchLine."Gen. Prod. Posting Group");
                    VATPostSetup.GET(CheckPurchLine."VAT Bus. Posting Group", CheckPurchLine."VAT Prod. Posting Group");

                    Item.GET(CheckPurchLine."No.");
                    IF NOT ItemTrackingCode.GET(Item."Item Tracking Code") THEN
                        ItemTrackingCode.INIT;

                    Item.TESTFIELD("Inventory Posting Group");
                    InvPostSetup.GET(CheckPurchLine."Location Code", Item."Inventory Posting Group");

                    LotTracking := ItemTrackingCode."Lot Specific Tracking";
                    SNTracking := ItemTrackingCode."SN Specific Tracking";
                    ReservationEntry.RESET;
                    ReservationEntry.SETRANGE("Source Type", DATABASE::"Purchase Line");
                    ReservationEntry.SETRANGE("Source Subtype", "Document Type");
                    ReservationEntry.SETRANGE("Source ID", "No.");
                    ReservationEntry.SETRANGE("Source Ref. No.", CheckPurchLine."Line No.");
                    ReservationEntry.SETFILTER("Qty. to Handle (Base)", '<>%1', 0);
                    IF LotTracking THEN
                        ReservationEntry.SETFILTER("Lot No.", '<>%1', '');
                    IF SNTracking THEN
                        ReservationEntry.SETFILTER("Serial No.", '<>%1', '');

                    CLEAR(SumQtyHandle);
                    IF ReservationEntry.FINDSET THEN
                        REPEAT
                            SumQtyHandle += ReservationEntry."Qty. to Handle (Base)";
                            IF (ItemTrackingCode."Man. Expir. Date Entry Reqd.") AND (ReservationEntry."Expiration Date" = 0D) AND
                               (ReservationEntry."Qty. to Handle (Base)" > 0) THEN
                                ERROR('Expiration Date is required for Item: %1\Check in Item tracking line...', CheckPurchLine."No.");
                        UNTIL ReservationEntry.NEXT = 0;

                    IF SNTracking OR LotTracking THEN
                        IF SumQtyHandle <> CheckPurchLine."Qty. to Receive (Base)" THEN
                            ERROR('Qty. to Receive not match Item Tracking Lines.\Item: %1\Qty. to Receive: %2\Item Tracking: %3', CheckPurchLine."No.", CheckPurchLine."Qty. to Receive (Base)", SumQtyHandle);
                END;
            UNTIL CheckPurchLine.NEXT = 0;
    end;

    var
        NoSeriesMgt: Codeunit NoSeriesManagement;
}