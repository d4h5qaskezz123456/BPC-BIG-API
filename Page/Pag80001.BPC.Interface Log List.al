page 80001 "BPC.Interface Log List"
{
    Caption = 'Interface Log List';
    CardPageID = "BPC.Interface Log Card";
    UsageCategory = Administration;
    ApplicationArea = all;
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "BPC.Interface Log API";
    SourceTableView = SORTING("BPC.Interface DateTime")
                      ORDER(descending)
                      WHERE("BPC.Interface Type" = FILTER(<> 'GetToken'));

    layout
    {
        area(content)
        {
            repeater(Interface)
            {
                field("BPC.Interface Type"; Rec."BPC.Interface Type")
                {
                }
                field("BPC.Document No."; Rec."BPC.Document No.")
                {
                }
                field("BPC.Error Occur"; Rec."BPC.Error Occur")
                {
                }
                field("BPC.Entry No."; Rec."BPC.Entry No.")
                {
                }
                field("BPC.Interface Date"; Rec."BPC.Interface Date")
                {
                }
                field("BPC.Interface Time"; Rec."BPC.Interface Time")
                {
                }
                field("BPC.Interface DateTime"; Rec."BPC.Interface DateTime")
                {
                }
                field("BPC.User ID"; Rec."BPC.User ID")
                {
                }
            }
        }
    }

    actions
    {
        area(creation)
        {
            action("Clear Interface Log")
            {
                Caption = 'Clear Interface Log';
                Image = ClearLog;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = Category4;
                //The property 'PromotedIsBig' can only be set if the property 'Promoted' is set to 'true'
                //PromotedIsBig = true;

                trigger OnAction()
                var
                    InterfaceLogAPI: Record "BPC.Interface Log API";
                begin
                    IF NOT CONFIRM('Do you want Clear Interface Log?') THEN
                        EXIT;
                    InterfaceLogAPI.RESET;
                    InterfaceLogAPI.COPY(Rec);
                    InterfaceLogAPI.DELETEALL;

                    CurrPage.UPDATE();
                end;
            }
            action(FillterInterfaceType)
            {
                Caption = 'Fillter Interface Type';
                Image = FilterLines;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    InterfaceLogAPI: Record "BPC.Interface Log API";
                    TempInterfaceLogAPI: Record "BPC.Interface Log API" temporary;
                begin
                    // Ton 2020/06/12 Create
                    InterfaceLogAPI.RESET;
                    InterfaceLogAPI.SETFILTER("BPC.Interface Type", '<>%1', 'GetToken');
                    IF InterfaceLogAPI.FINDSET THEN BEGIN
                        REPEAT
                            TempInterfaceLogAPI.RESET;
                            TempInterfaceLogAPI.SETFILTER("BPC.Interface Type", InterfaceLogAPI."BPC.Interface Type");
                            IF NOT TempInterfaceLogAPI.FINDSET THEN BEGIN
                                TempInterfaceLogAPI.INIT;
                                TempInterfaceLogAPI.TRANSFERFIELDS(InterfaceLogAPI);
                                TempInterfaceLogAPI.INSERT;
                            END;
                        UNTIL InterfaceLogAPI.NEXT = 0;
                    END;

                    TempInterfaceLogAPI.RESET;
                    IF PAGE.RUNMODAL(PAGE::"BPC.Fillter Interface Type", TempInterfaceLogAPI) = ACTION::LookupOK THEN BEGIN
                        rec.FILTERGROUP(2);
                        rec.RESET;
                        rec.SETFILTER("BPC.Interface Type", TempInterfaceLogAPI."BPC.Interface Type");
                        rec.FILTERGROUP(0);
                        CurrPage.UPDATE();
                    END;
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        OfficeMgt: Codeunit "Office Management";
    begin
    end;
}

