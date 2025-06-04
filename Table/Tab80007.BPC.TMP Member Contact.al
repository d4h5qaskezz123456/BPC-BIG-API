table 80007 "BPC.TMP Member Contact"
{
    Caption = 'TMP Member Contact';

    fields
    {
        field(80000; "BPC Account No."; Code[20])
        {

        }
        field(80001; "BPC Name"; Text[200])
        {

        }
        field(80002; "BPC Address"; Text[200])
        {

        }
        field(80003; "BPC City"; Text[30])
        {

        }
        field(80004; "BPC Post Code"; Code[20])
        {

        }
        field(80005; "BPC VAT Registration No."; Code[20])
        {

        }
        field(80006; "BPC Mobile Phone No."; Text[30])
        {

        }
        field(80007; "BPC Phone No."; Code[30])
        {

        }
        // field(80008; "BPC E-Mail"; Text[30])//NM Comment 20250310
        field(80008; "BPC E-Mail"; Text[80])//NM Insert 20250310 fot extend leght email
        {

        }
        field(80009; "BPC Date of Birth"; Text[30])
        {

        }
        field(80010; "BPC Gender"; Text[50])
        {

        }

    }
    keys
    {
        key(Key1; "BPC Account No.")
        {
            Clustered = true;
        }
    }

}

