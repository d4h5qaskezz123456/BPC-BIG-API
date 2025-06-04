pageextension 80012 "BPC.Store P. Transfer Shipment" extends "LSC Store P. Transfer Shipment"
{
    layout
    {
        // Add changes to page layout here
    }
    actions
    {
        addafter("&Print")
        {
            action(ReSendPostTransfersShipment)
            {
                ApplicationArea = Location;
                Caption = 'Re-Send Shipment to D365';
                Image = Action;
                Promoted = true;
                PromotedCategory = Process;
                trigger OnAction()
                var
                    ErrText: Text;
                begin
                    RetailSetup.Get();
                    if Confirm('Re-Send Shipment to D365 ?', true, Rec."No.") then begin
                        RetailSetup.TestField("bpc.Interface D365 Active");
                        TransferShipmentHeader.Reset();
                        TransferShipmentHeader.SetRange("No.", rec."No.");
                        if TransferShipmentHeader.FindSet() then
                            ReSendInterface.ReSendPostTransfersShipment(TransferShipmentHeader)
                    end;
                end;


            }
        }
    }


    var
        TransferShipmentHeader: Record "Transfer Shipment Header";
        ReSendInterface: Codeunit "BPC.ReSend Interface";
        RetailSetup: Record "LSC Retail Setup";

}