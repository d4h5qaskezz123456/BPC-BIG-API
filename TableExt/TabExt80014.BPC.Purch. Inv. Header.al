tableextension 80014 "BPC.Purch. Inv. Header" extends "Purch. Inv. Header"
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


        }
        field(80110; "BPC.Branch No. Pay-to"; Code[5])
        {
            Caption = 'Branch No. Pay-to';
            DataClassification = ToBeClassified;
            Description = 'LCBC1.0';

        }
        field(80111; "BPC.PO No. Series"; Code[10])
        {
            Caption = 'PO No. Series';
            DataClassification = ToBeClassified;
            Description = 'LCBC1.0';

            ;
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
    var
}