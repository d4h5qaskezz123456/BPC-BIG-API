table 80010 "BPC.API Sales&PurchaseHdrBuff"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            DataClassification = CustomerContent;
        }
        field(2; "Sell-to Customer Name"; Text[100])
        {
            DataClassification = CustomerContent;
        }
        field(3; "Sell-to Customer No."; Code[20])
        {
            DataClassification = CustomerContent;
        }
        field(4; "Ship-to Code"; Code[10])
        {
            DataClassification = CustomerContent;
        }
        field(5; "Bill-to Customer No."; Code[20])
        {
            DataClassification = CustomerContent;
        }
        field(6; "Location Code"; Code[10])
        {
            DataClassification = CustomerContent;
        }
        field(7; "VAT Bus. Posting Group"; Code[20])
        {
            DataClassification = CustomerContent;
        }
        field(8; "BPC.Reference Online Order"; Code[50])
        {
            DataClassification = CustomerContent;
        }
        field(9; "Ship-to Address"; Text[100])
        {
            DataClassification = CustomerContent;
        }
        field(10; "Ship-to Address 2"; Text[50])
        {
            DataClassification = CustomerContent;
        }
        field(11; "Ship-to Post Code"; Code[20])
        {
            DataClassification = CustomerContent;
        }
        field(12; "Ship-to City"; Text[30])
        {
            DataClassification = CustomerContent;
        }
        field(13; "Ship-to Country/Region Code"; Code[10])
        {
            DataClassification = CustomerContent;
        }
        field(14; "Ship-to Name"; Text[100])
        {
            DataClassification = CustomerContent;
        }
        field(15; "Bill-to Name"; Text[100])
        {
            DataClassification = CustomerContent;
        }
        field(16; "Bill-to Address"; Text[100])
        {
            DataClassification = CustomerContent;
        }
        field(17; "Bill-to Address 2"; Text[50])
        {
            DataClassification = CustomerContent;
        }
        field(18; "Bill-to Post Code"; Code[20])
        {
            DataClassification = CustomerContent;
        }
        field(19; "Bill-to City"; Text[30])
        {
            DataClassification = CustomerContent;
        }
        field(20; "Bill-to Country/Region Code"; Code[10])
        {
            DataClassification = CustomerContent;
        }
        field(21; "VAT Registration No."; Text[20])
        {
            DataClassification = CustomerContent;
        }
        field(22; "Invoice Discount Value"; Decimal)
        {
            DataClassification = CustomerContent;
        }
        field(23; "Shipment Method Code"; Code[10])
        {
            DataClassification = CustomerContent;
        }
        field(24; "Shipment Date"; Date)
        {
            DataClassification = CustomerContent;
        }
        field(25; "Requested Delivery Date"; Date)
        {
            DataClassification = CustomerContent;
        }
        field(26; Status; Enum "Sales Document Status")
        {
            DataClassification = CustomerContent;
        }
        field(27; Company; Text[100])
        {
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; Company)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    var
        myInt: Integer;

    trigger OnInsert()
    begin

    end;

    trigger OnModify()
    begin

    end;

    trigger OnDelete()
    begin

    end;

    trigger OnRename()
    begin

    end;

}