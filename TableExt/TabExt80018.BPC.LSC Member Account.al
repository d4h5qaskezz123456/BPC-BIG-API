tableextension 80018 "BPC.LSC Member Account" extends "LSC Member Account"
{
    fields
    {

        field(80100; "BPC.Description 2"; Text[150])
        {
            Caption = 'Description 2';
        }
    }
    trigger OnInsert()
    var
        myInt: Integer;
    begin
    end;

    var
}