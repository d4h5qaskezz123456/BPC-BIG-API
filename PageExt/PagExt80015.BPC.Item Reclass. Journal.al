pageextension 80015 "BPC.Item Reclass. Journal" extends "Item Reclass. Journal"
{
    layout
    {
        addafter("Applies-to Entry")
        {
            field("Serial No."; Rec."Serial No.")
            {
                ApplicationArea = app;
            }
            field("New Serial No."; Rec."New Serial No.")
            {
                ApplicationArea = app;
            }
            field("Lot No."; Rec."Lot No.")
            {
                ApplicationArea = app;
            }
            field("New Lot No."; Rec."New Lot No.")
            {
                ApplicationArea = app;
            }
        }
    }
    actions
    {
        modify(Post)
        {
            // trigger OnAfterAction()
            // var
            //     InterfaceData: Codeunit "BPC.Interface Data";
            //     RetailSetup: Record "LSC Retail Setup";
            // begin
            //     RetailSetup.GET;
            //     IF RetailSetup."BPC.Interface D365 Active" THEN BEGIN
            //         InterfaceData.PostTransferJournal();
            //     end;
            //     // rec."Document No." := '';
            //     // rec.Modify();
            //     CurrPage.Update();
            // end;

            trigger OnBeforeAction()
            var
                InterfaceData: Codeunit "BPC.Interface Data";
                TMPItemLedgEntry: Record "BPC.TMPItemLedgEntry";
            begin
                TMPItemLedgEntry.Reset();
                TMPItemLedgEntry.SetRange(TMPItemLedgEntry."User ID", UserId);
                if TMPItemLedgEntry.FindSet() then
                    TMPItemLedgEntry.DeleteAll();
            end;
        }
        modify("Post and &Print")
        {
            trigger OnBeforeAction()
            var
                InterfaceData: Codeunit "BPC.Interface Data";
                TMPItemLedgEntry: Record "BPC.TMPItemLedgEntry";
            begin
                TMPItemLedgEntry.Reset();
                TMPItemLedgEntry.SetRange(TMPItemLedgEntry."User ID", UserId);
                if TMPItemLedgEntry.FindSet() then
                    TMPItemLedgEntry.DeleteAll();
            end;
        }
    }


    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        ReSendInterface: Codeunit "BPC.ReSend Interface";
        RetailSetup: Record "LSC Retail Setup";

}