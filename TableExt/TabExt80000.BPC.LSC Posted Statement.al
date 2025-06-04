tableextension 80000 "BPC.LSC Posted Statement" extends "LSC Posted Statement"
{
    fields
    {
        field(80100; "BPC.Journal ID"; Code[50])
        {
            Caption = 'Journal ID';
        }
        field(80101; "BPC.Movement ID"; Code[50])
        {
            Caption = 'Movement ID';
        }
        field(80102; "BPC Send To FO"; Boolean)
        {
            Caption = 'Send To FO';
            Editable = false;
        }
    }

    var
        myInt: Integer;
}