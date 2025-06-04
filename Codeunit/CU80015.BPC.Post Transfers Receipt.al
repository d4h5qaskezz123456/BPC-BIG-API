codeunit 80015 "BPC.Post Transfers Receipt"
{
    Permissions = tabledata 110 = rim;
    trigger OnRun()
    var
    begin
        RunJobPostTransfersReceipt();
    end;

    local procedure RunJobPostTransfersReceipt()
    var
        Location: Record Location;
        TransferReceiptHeader: record "Transfer Receipt Header";
        RetailSetup: Record "LSC Retail Setup";
        ReSendInterface: Codeunit "BPC.ReSend Interface";
        ErrText: Text;
    begin
        RetailSetup.Get();
        TransferReceiptHeader.Reset();
        TransferReceiptHeader.SetRange("BPC Send To FO", false);
        if TransferReceiptHeader.FindSet() then
            repeat
                if not Location.Get(TransferReceiptHeader."Transfer-from Code") then
                    Location.Init();
                IF (RetailSetup."BPC.Interface D365 Active") and (not Location."BPC.Not sent to FO") THEN begin
                    ReSendInterface.ReSendPostTransfersReceipt(TransferReceiptHeader, false, ErrText);
                    TransferReceiptHeader."BPC Send To FO" := true;
                    TransferReceiptHeader.Modify();
                end;
            until TransferReceiptHeader.Next() = 0;
    end;
}