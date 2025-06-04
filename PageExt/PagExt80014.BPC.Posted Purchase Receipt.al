pageextension 80014 "BPC.Posted Purchase Receipt" extends "Posted Purchase Receipt"
{
    layout
    {
        // Add changes to page layout here
    }
    actions
    {
        addafter("&Print")
        {
            action(ReSendSendPurchaseReceive)
            {
                ApplicationArea = Location;
                Caption = 'Re-Sent PO Receive to 365';
                Image = Action;
                Promoted = true;
                PromotedCategory = Process;
                trigger OnAction()
                var
                    ErrText: Text;
                begin
                    RetailSetup.Get();
                    if Confirm('Re-Sent PO Receive to 365 ?', true, Rec."No.") then begin
                        RetailSetup.TestField("bpc.Interface D365 Active");
                        PurchRcptHeader.Reset();
                        PurchRcptHeader.SetRange("No.", rec."No.");
                        if PurchRcptHeader.FindSet() then
                            ReSendInterface.ReSendSendPurchaseReceive(PurchRcptHeader)
                    end;
                end;


            }
        }
    }


    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        ReSendInterface: Codeunit "BPC.ReSend Interface";
        RetailSetup: Record "LSC Retail Setup";

}