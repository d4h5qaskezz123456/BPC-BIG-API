pageextension 80002 "BPC.LSCRetailPurchaseOrder" extends "LSC Retail Purchase Order"
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {


    }
    trigger OnOpenPage()
    var
        myInt: Integer;
    begin
        RetailSetup.GET();
        IF RetailSetup."BPC.Interface D365 Active" THEN BEGIN
            InterfaceDocumentStatus.RESET;
            InterfaceDocumentStatus.SETRANGE("BPC.Document Type", InterfaceDocumentStatus."BPC.Document Type"::GRN);
            InterfaceDocumentStatus.SETRANGE("BPC.Reference Document No.", Rec."No.");
            InterfaceDocumentStatus.SETRANGE("BPC.Posted At FO", FALSE);
            IF InterfaceDocumentStatus.FINDSET THEN
                REPEAT
                    IF PurchRcptHeader.GET(InterfaceDocumentStatus."BPC.Document No.") THEN
                        InterfaceData.GetGRNStatus(PurchRcptHeader, TRUE);
                UNTIL InterfaceDocumentStatus.NEXT = 0;

            if rec."No." = '' then
                Error('ไม่อนุญาตให้ New รายการใหม่!');

            if Rec.Status = rec.Status::Cancel then
                Error('PO Cancel');

            // if (Rec.Status <> rec.Status::Cancel) then
            //     InterfaceData.GetPurchaseLine(Rec)
            // else
            //     Error('PO Cancel');
        end;
    end;

    var
        RetailSetup: Record "LSC Retail Setup";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        ReleasePurchDoc: Codeunit "Release Purchase Document";
        InterfaceData: Codeunit "BPC.Interface Data";
        InterfaceDocumentStatus: Record "BPC.Interface Document Status";
}