tableextension 80001 "BPC.LSC Retail Setup" extends "LSC Retail Setup"
{
    fields
    {
        field(80100; "BPC.D365 Connection Active"; Boolean)
        {
            Caption = 'D365 Connection Active';
        }
        field(80101; "BPC.Require Member on Sales Trans."; Option)
        {
            OptionMembers = "Ask","Mandatory";
            Caption = 'Require Member on Sales Trans.';
        }
        field(80102; "BPC.Interface D365 Active"; Boolean)
        {
            Caption = 'Interface D365 Active';
        }
        field(80103; "BPC.Interface User Name"; Text[100])
        {
            Caption = 'Interface User Name';
        }
        field(80104; "BPC.Interface Password"; Text[100])
        {
            Caption = 'Interface Password';
        }
        field(80105; "BPC.Interface ClientID"; Text[100])
        {
            Caption = 'Interface ClientID';
        }
        field(80106; "BPC.Interface Client Secret"; Text[100])
        {
            Caption = 'Interface Client Secret';
        }
        field(80107; "BPC.Interface Resource"; Text[100])
        {
            Caption = 'Interface Resource';
        }
        field(80108; "BPC.Interface Company"; Text[100])
        {
            Caption = 'Interface Company';
        }
        field(80109; "BPC.Interface Tenant ID"; Text[100])
        {
            Caption = 'Interface Tenant ID';
        }
        field(80110; "BPC.LS Post Receive before Sent"; Boolean)
        {
            Caption = 'LS Post Receive before Sent';
        }

    }

    var
        myInt: Integer;
}