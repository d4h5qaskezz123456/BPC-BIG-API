codeunit 80012 "BPC.Post Transfers Shipment"
{
    Permissions = tabledata 110 = rim;
    trigger OnRun()
    var
    begin
        RunJobPostTransfersShipment();
    end;

    local procedure RunJobPostTransfersShipment()
    var
        Location: Record Location;
        TransferShipmentHeader: record "Transfer Shipment Header";
        RetailSetup: Record "LSC Retail Setup";
        ReSendInterface: Codeunit "BPC.ReSend Interface";
    begin

        RetailSetup.Get();
        TransferShipmentHeader.Reset();
        TransferShipmentHeader.SetRange("BPC Send To FO", false);
        if TransferShipmentHeader.FindSet() then
            repeat
                if not Location.Get(TransferShipmentHeader."Transfer-from Code") then
                    Location.Init();
                if (RetailSetup."BPC.Interface D365 Active") and (not Location."BPC.Not sent to FO") then begin
                    ReSendInterface.ReSendPostTransfersShipment(TransferShipmentHeader);
                    TransferShipmentHeader."BPC Send To FO" := true;
                    TransferShipmentHeader.Modify();
                end;
            until TransferShipmentHeader.Next() = 0;
    end;
}