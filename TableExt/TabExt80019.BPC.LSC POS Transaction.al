tableextension 80019 "LSC POS Transaction" extends "LSC POS Transaction"
{
    fields
    {

        field(80101; "BPC.Sales Order Posting Date"; Date)
        {
            DataClassification = ToBeClassified;
            Caption = 'Sales Order Posting Date';
        }
        field(80102; "BPC.Sales Order Document Date"; Date)
        {
            DataClassification = ToBeClassified;
            Caption = 'Sales Order Document Date';
        }
        field(80103; "BPC.Bill-to Address"; Text[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'Bill-to Address';
        }
        field(80104; "BPC.Bill-to Address 2"; Text[50])
        {
            DataClassification = ToBeClassified;
            Caption = 'Bill-to Address 2';
        }
        field(80109; "BPC.Bill-to City"; Text[30])
        {
            DataClassification = ToBeClassified;
            Caption = 'Bill-to City';
        }
        field(80110; "BPC.Bill-to County"; Text[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'Bill-to County';
        }
        field(80111; "BPC.Bill-to Post Code"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Bill-to Post Code';
        }
        field(80112; "BPC.Bill-to Name"; Text[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'Bill-to Name';
        }

    }

    var
}