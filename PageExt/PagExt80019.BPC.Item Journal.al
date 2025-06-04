pageextension 80019 "BPC.Item Journal" extends "Item Journal"
{
    layout
    {
        addafter("Unit of Measure Code")
        {
            field("BPC.Remark"; Rec."BPC.Remark")
            {
                ApplicationArea = all;
            }
        }
    }
    actions
    {
        modify(Post)
        {

            trigger OnBeforeAction()
            var
                TMPItemLedgEntry: Record "BPC.TMPItemLedgEntry";
            begin
                TMPItemLedgEntry.Reset();
                TMPItemLedgEntry.SetRange(TMPItemLedgEntry."User ID", UserId);
                if TMPItemLedgEntry.FindSet() then begin
                    repeat
                        TMPItemLedgEntry.Delete();
                    until TMPItemLedgEntry.Next() = 0
                end;
            end;
        }
        modify("Post and &Print")
        {
            trigger OnBeforeAction()
            var
                TMPItemLedgEntry: Record "BPC.TMPItemLedgEntry";
            begin
                TMPItemLedgEntry.Reset();
                TMPItemLedgEntry.SetRange(TMPItemLedgEntry."User ID", UserId);
                if TMPItemLedgEntry.FindSet() then begin
                    repeat
                        TMPItemLedgEntry.Delete();
                    until TMPItemLedgEntry.Next() = 0
                end;
            end;
        }
    }


    var


}