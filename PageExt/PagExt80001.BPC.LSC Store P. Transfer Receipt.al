pageextension 80001 "BPC.Store P. Transfer Receipt" extends "LSC Store P. Transfer Receipt"
{
    layout
    {
        // Add changes to page layout here
    }
    actions
    {
        addafter("&Print")
        {
            action(ReSendPostTransfersReceipt)
            {
                ApplicationArea = Location;
                Caption = 'Re-Sent Receive to 365';
                Image = Action;
                Promoted = true;
                PromotedCategory = Process;
                trigger OnAction()
                var
                    ErrText: Text;
                begin
                    RetailSetup.Get();
                    if Confirm('Re-Sent Receive to 365 ?', true, Rec."No.") then begin
                        // RetailSetup.TestField("bpc.Interface D365 Active");
                        TransferReceiptHeader.Reset();
                        TransferReceiptHeader.SetRange("No.", rec."No.");
                        if TransferReceiptHeader.FindSet() then
                            ReSendInterface.ReSendPostTransfersReceipt(TransferReceiptHeader, FALSE, ErrText)

                    end;
                end;
            }
        }
    }


    var
        TransferReceiptHeader: Record "Transfer Receipt Header";
        ReSendInterface: Codeunit "BPC.ReSend Interface";
        RetailSetup: Record "LSC Retail Setup";
}