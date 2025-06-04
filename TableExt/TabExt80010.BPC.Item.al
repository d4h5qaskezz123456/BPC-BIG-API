tableextension 80010 "BPC Item" extends Item
{
    fields
    {
        field(80101; "BPC.Coverage Day"; Integer)
        {
            Caption = 'Coverage Day';
            InitValue = 14;
        }
        field(80102; "BPC.Brand"; code[30])
        {
            Caption = 'Brand';
        }
        field(80103; "BPC.Brand Description"; text[255])
        {
            Caption = 'Brand Description';
        }
        field(80104; "BPC.Model"; code[30])
        {
            Caption = 'Model';
        }
        field(80105; "BPC.Model Description"; text[255])
        {
            Caption = 'Model Description';
        }
        field(80106; "BPC.Type"; code[30])
        {
            Caption = 'Type';
        }
        field(80107; "BPC.Type Description"; text[255])
        {
            Caption = 'Type Description';
        }
        field(80108; "BPC.Size"; code[30])
        {
            Caption = 'Size';
        }
        field(80109; "BPC.Size Description"; text[255])
        {
            Caption = 'Size Description';
        }
        field(80110; "BPC.Type 1"; code[30])
        {
            Caption = 'Type 1';
        }
        field(80111; "BPC.Type1 Description"; text[255])
        {
            Caption = 'Type1 Description';
        }

        field(80112; "BPC.Type 2"; code[30])
        {
            Caption = 'Type 2';
        }
        field(80113; "BPC.Type2 Description"; text[255])
        {
            Caption = 'Type2 Description';
        }
        field(80114; "BPC.Inventory Stoped"; Boolean)
        {
            Caption = 'Inventory Stoped';
        }
        field(80115; "BPC.Purchase Stoped"; Boolean)
        {
            Caption = 'Purchase Stoped';
        }
        field(80116; "BPC.Sale Stoped"; Boolean)
        {
            Caption = 'Sale Stoped';
        }
        field(80117; "BPC.Modified date and time"; DateTime)
        {
            Caption = 'Modified date and time';
        }
        //--A-- 2024/11/15 ++
        field(80118; "BPC.Block Update Type"; Boolean)
        {
            Caption = 'Block Update Type';
            DataClassification = CustomerContent;
        }
        //--A-- 2024/11/15 --
    }

    var
}