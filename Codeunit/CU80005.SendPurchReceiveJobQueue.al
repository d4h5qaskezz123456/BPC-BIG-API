//Kim 2025-05 ++
codeunit 80005 "BPC.API.SendPurchReceiveJobQue"
{
    trigger OnRun()
    begin
        Code();
    end;

    local procedure Code()
    var
        RetailSetup: Record "LSC Retail Setup";
        PurchaseHeader: record "Purchase Header";
        PurchRcptHeader: record "Purch. Rcpt. Header";
        InterfaceData: Codeunit "BPC.Interface Data";
    begin
        RetailSetup.Get();
        if RetailSetup."BPC.Interface D365 Active" then begin
            PurchRcptHeader.SetRange("BPC.To D365", false);
            if PurchRcptHeader.FindSet() then
                repeat
                    PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchRcptHeader."Order No.");
                    InterfaceData.SendPurchaseReceive(PurchaseHeader, PurchRcptHeader."No.");
                until PurchRcptHeader.Next() = 0;
        end;
    end;
}
//Kim 2025-05 --