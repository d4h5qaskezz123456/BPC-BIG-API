page 80009 "BPC.Interface Log Member"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Documents;
    SourceTable = "BPC.API Log Member Contact";
    Editable = false;
    DeleteAllowed = false;
    Caption = 'Interface Log Member';
    layout
    {
        area(Content)
        {
            repeater(GroupConnect)
            {
                field("Entry No."; rec."Entry No.")
                {
                    Editable = false;
                }
                field("Method Name"; rec."Method Name")
                {
                    Editable = false;
                }
                field(Description; rec.Description)
                {
                    Editable = false;
                }
                field("Employee No."; rec."Employee No.")
                {
                    Editable = false;
                }
                field(Status; rec.Status)
                {
                    Editable = false;
                }
                field("Created DateTime"; rec."Created DateTime")
                {
                    Editable = false;
                }
                field("Created Date"; rec."Created Date")
                {
                    Editable = false;
                }
                field("Created Time"; rec."Created Time")
                {
                    Editable = false;
                }

            }
        }
    }

    var

}