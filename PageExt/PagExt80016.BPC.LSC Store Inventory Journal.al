pageextension 80016 "BPC.LSCStoreInventoryJournal" extends "LSC Store Inventory Journal"
{
    layout
    {
        modify("Unit of Measure Code")
        {
            Editable = true;
            Enabled = true;
        }
    }
    actions
    {
        modify("Process/Post")
        {
            trigger OnAfterAction()
            var
                InterfaceData: Codeunit "BPC.Interface Data";
                RetailSetup: Record "LSC Retail Setup";
                TMPItemLedgEntry: Record "BPC.TMPItemLedgEntry";
            begin
                RetailSetup.GET;
                IF RetailSetup."BPC.Interface D365 Active" THEN BEGIN
                    TMPItemLedgEntry.SetRange("User ID", UserId);
                    TMPItemLedgEntry.SetRange("Entry Type", TMPItemLedgEntry."Entry Type"::Transfer);
                    if TMPItemLedgEntry.FindSet() then begin
                        InterfaceData.PostTransferJournal();
                    end;
                end;
            end;

            trigger OnBeforeAction()
            var
                InterfaceData: Codeunit "BPC.Interface Data";
                TMPItemLedgEntry: Record "BPC.TMPItemLedgEntry";
            begin
                TMPItemLedgEntry.SetRange("User ID", UserId);
                TMPItemLedgEntry.SetRange("Entry Type", TMPItemLedgEntry."Entry Type"::Transfer);
                if TMPItemLedgEntry.FindSet() then begin
                    TMPItemLedgEntry.DeleteAll();
                end;
            end;
        }
    }


    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        ReSendInterface: Codeunit "BPC.ReSend Interface";
        RetailSetup: Record "LSC Retail Setup";

}