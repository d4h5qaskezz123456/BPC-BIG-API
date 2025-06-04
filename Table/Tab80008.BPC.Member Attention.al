table 80008 "BPC.Member Attention"
{
    Caption = 'Member Attention';

    fields
    {
        field(80000; "BPC Member Account No."; Code[20])
        {

        }
        field(80001; "BPC Attention ID"; Code[20])
        {

        }
        field(80002; "BPC Attention Text"; Text[200])
        {

        }
        field(80003; "BPC Atten_1"; Text[20])
        {

        }
        field(80004; "BPC Atten_2"; Text[20])
        {

        }
        field(80005; "BPC Atten_3"; Text[20])
        {

        }
        field(80006; "BPC Atten_4"; Text[20])
        {

        }
        field(80007; "BPC Atten_5"; Text[20])
        {

        }
        field(80008; "BPC Atten_6"; Text[20])
        {

        }
        field(80009; "BPC Atten_7"; Text[20])
        {

        }
        field(80010; "BPC Atten_8"; Text[20])
        {

        }
        field(80011; "BPC Atten_9"; Text[20])
        {

        }
        field(80012; "BPC Atten_10"; Text[20])
        {

        }

    }
    keys
    {
        key(Key1; "BPC Member Account No.", "BPC Attention ID")
        {
            Clustered = true;
        }
    }

}

