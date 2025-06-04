table 80006 "BPC.TMPItemLedgEntry"
{
    Caption = 'TMPItemLedgEntry';

    fields
    {
        field(80000; "Entry No."; Integer)
        {

        }

        field(80001; "Document No."; Code[20])
        {

        }
        field(80002; "Warehouse"; Code[10])
        {

        }
        field(80003; "Item No."; Code[20])
        {

        }
        field(80005; "User ID"; Text[100])
        {

        }
        field(80006; "Reason Code"; Code[20])
        {

        }
        field(80007; "BPC.Location code"; Code[20])
        {

        }
        field(80008; "BPC.New Location code"; Code[20])
        {

        }
        field(80009; "Entry Type"; Enum "Item Ledger Entry Type")
        {
            Caption = 'Entry Type';
        }
        field(80010; QTY; Decimal)
        {
        }
        field(80011; "Line No."; Integer)
        {
        }
        field(80012; "Lot No."; Code[20])
        {

        }
        field(80013; "New Lot No."; Code[20])
        {
        }
        field(80014; "Serial No."; Code[20])
        {
        }
        field(80015; "New Serial No."; Code[20])
        {
        }

    }
    keys
    {
        key(Key1; "Document No.", "Entry No.")
        {
            Clustered = true;
        }
    }

}

