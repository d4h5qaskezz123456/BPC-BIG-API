page 80002 "BPC.Fillter Interface Type"
{
    Caption = 'Fillter Interface Type';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "BPC.Interface Log API";
    ;
    SourceTableView = SORTING("BPC.Interface Type", "BPC.Document No.", "BPC.Entry No.")
                      ORDER(Ascending)
                      WHERE("BPC.Interface Type" = FILTER(<> 'GetToken'));

    layout
    {
        area(content)
        {
            repeater(Interface)
            {
                field("BPC.Interface Type"; Rec."BPC.Interface Type")
                {
                    ApplicationArea = all;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        OfficeMgt: Codeunit "Office Management";
    begin
    end;
}

