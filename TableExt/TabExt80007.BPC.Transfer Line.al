tableextension 80007 "BPC.Transfer Lines" extends "Transfer Line"
{
    fields
    {
        field(80100; "BPC.Location Code"; Code[10])
        {
            Caption = 'Location Code';
        }
        field(80101; "BPC.Serial No."; Code[50])
        {
            Caption = 'Serial No.';
        }
        field(80102; "BPC.Active"; Boolean)
        {
            Caption = 'Active';
        }
        field(80103; "BPC.Interface"; Boolean)
        {
            Caption = 'Interface';
        }

    }

    var
        myInt: page 10000815;
}