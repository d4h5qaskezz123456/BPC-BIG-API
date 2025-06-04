#region Import Item Ledger
//Kim 2025-03 ++
xmlport 80000 "BPC.API.ImportItemLedger"
{
    Caption = 'Import Item Ledger';
    Format = VariableText;
    FieldDelimiter = '<None>';
    FieldSeparator = '<TAB>';
    UseRequestPage = false;
    Direction = Import;
    TextEncoding = WINDOWS;
    Permissions = tabledata "Item Ledger Entry" = rimd, tabledata "Value Entry" = rimd;

    schema
    {
        textelement(Root)
        {
            tableelement(ImportItemLedgerEntry; "Item Ledger Entry")
            {
                AutoSave = false;
                fieldelement(F1; ImportItemLedgerEntry."Entry No.") { }
                textelement(F2) { }
                fieldelement(F3; ImportItemLedgerEntry."Item No.") { }
                fieldelement(F4; ImportItemLedgerEntry.Description) { }
                fieldelement(F5; ImportItemLedgerEntry."Serial No.") { }
                fieldelement(F6; ImportItemLedgerEntry.Quantity) { }
                fieldelement(F7; ImportItemLedgerEntry."Unit of Measure Code") { }
                fieldelement(F8; ImportItemLedgerEntry."Location Code") { }
                fieldelement(F9; ImportItemLedgerEntry."Qty. per Unit of Measure") { }
                fieldelement(F10; ImportItemLedgerEntry."Posting Date") { }
                fieldelement(F11; ImportItemLedgerEntry."Entry Type") { }
                fieldelement(F12; ImportItemLedgerEntry."Source Type") { }
                fieldelement(F13; ImportItemLedgerEntry."Source No.") { }
                textelement(F14) { }
                textelement(F15) { }
                fieldelement(F16; ImportItemLedgerEntry."Document No.") { }
                fieldelement(F17; ImportItemLedgerEntry."Remaining Quantity") { }
                fieldelement(F18; ImportItemLedgerEntry."Invoiced Quantity") { }
                fieldelement(F19; ImportItemLedgerEntry."Applies-to Entry") { }
                fieldelement(F20; ImportItemLedgerEntry.Open) { }
                fieldelement(F21; ImportItemLedgerEntry."Dimension Set ID") { }
                fieldelement(F22; ImportItemLedgerEntry."Global Dimension 1 Code") { }
                fieldelement(F23; ImportItemLedgerEntry."Global Dimension 2 Code") { }
                fieldelement(F24; ImportItemLedgerEntry.Positive) { }
                fieldelement(F25; ImportItemLedgerEntry."Shpt. Method Code") { }
                fieldelement(F26; ImportItemLedgerEntry."Transaction Type") { }
                fieldelement(F27; ImportItemLedgerEntry."Transport Method") { }
                fieldelement(F28; ImportItemLedgerEntry."Document Date") { }
                fieldelement(F29; ImportItemLedgerEntry."External Document No.") { }
                fieldelement(F30; ImportItemLedgerEntry."Area") { }
                fieldelement(F31; ImportItemLedgerEntry."Transaction Specification") { }
                fieldelement(F32; ImportItemLedgerEntry."No. Series") { }
                fieldelement(F33; ImportItemLedgerEntry."Document Type") { }
                fieldelement(F34; ImportItemLedgerEntry."Document Line No.") { }
                fieldelement(F35; ImportItemLedgerEntry."Order Type") { }
                fieldelement(F36; ImportItemLedgerEntry."Order No.") { }
                fieldelement(F37; ImportItemLedgerEntry."Order Line No.") { }
                fieldelement(F38; ImportItemLedgerEntry."Assemble to Order") { }
                fieldelement(F39; ImportItemLedgerEntry."Job No.") { }
                fieldelement(F40; ImportItemLedgerEntry."Job Task No.") { }
                fieldelement(F41; ImportItemLedgerEntry."Job Purchase") { }
                textelement(F42) { }
                fieldelement(F43; ImportItemLedgerEntry."Variant Code") { }
                fieldelement(F44; ImportItemLedgerEntry."Lot No.") { }
                textelement(F45) { }
                fieldelement(F46; ImportItemLedgerEntry."Item Category Code") { }
                fieldelement(F47; ImportItemLedgerEntry."LSC Retail Product Code") { }
                fieldelement(F48; ImportItemLedgerEntry."Completely Invoiced") { }
                fieldelement(F49; ImportItemLedgerEntry."Last Invoice Date") { }
                fieldelement(F50; ImportItemLedgerEntry."Applied Entry to Adjust") { }
                fieldelement(F51; ImportItemLedgerEntry.Correction) { }
                fieldelement(F52; ImportItemLedgerEntry."Shipped Qty. Not Returned") { }
                fieldelement(F53; ImportItemLedgerEntry."Expiration Date") { }
                fieldelement(F54; ImportItemLedgerEntry."Item Tracking") { }
                fieldelement(F55; ImportItemLedgerEntry."Return Reason Code") { }
                fieldelement(F56; ImportItemLedgerEntry."BPC.By") { }
                fieldelement(F57; ImportItemLedgerEntry."BPC.User ID") { }
                fieldelement(F58; ImportItemLedgerEntry."BPC.Remark") { }
                fieldelement(F59; ImportItemLedgerEntry."BPC.Statement No.") { }
                fieldelement(F60; ImportItemLedgerEntry."LSC Offer No.") { }
                fieldelement(F61; ImportItemLedgerEntry."LSC Batch No.") { }
                textelement(F62) { }
                fieldelement(F63; ImportItemLedgerEntry."LSC Promotion No.") { }
                fieldelement(F64; ImportItemLedgerEntry."LSC Transfer Type") { }
                fieldelement(F65; ImportItemLedgerEntry."LSC Statement No.") { }
                textelement(F66) { }
                textelement(F67) { }
                textelement(F68) { }
                textelement(F69) { }
                textelement(F70) { }
                textelement(F71) { }
                textelement(F72) { }
                textelement(F73) { }
                textelement(F74) { }
                textelement(F75) { }
                textelement(F76) { }
                textelement(F77) { }
                textelement(F78) { }
                textelement(F79) { }
                textelement(F80) { }
                textelement(F81) { }
                textelement(F82) { }
                textelement(F83) { }
                textelement(F84) { }
                textelement(F85) { }
                textelement(F86) { }

                trigger OnBeforeInsertRecord()
                begin
                    InsertItemLedgerEntry();
                end;

                trigger OnBeforeModifyRecord()
                begin
                    InsertItemLedgerEntry();
                end;
            }
        }
    }

    local procedure InsertItemLedgerEntry()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        VEEntryNo: Integer;
    begin
        ItemLedgerEntry := ImportItemLedgerEntry;
        ItemLedgerEntry.Insert();

        if ValueEntry.FindLast() then
            VEEntryNo := ValueEntry."Entry No.";

        Evaluate(ValueEntry."Item Ledger Entry No.", F2);
        ValueEntry."Item No." := ItemLedgerEntry."Item No.";
        ValueEntry."LSC Item No." := ItemLedgerEntry."Item No.";
        ValueEntry.Description := ItemLedgerEntry.Description;
        ValueEntry."Item Ledger Entry Quantity" := ItemLedgerEntry.Quantity;
        ValueEntry."Valued Quantity" := ItemLedgerEntry.Quantity;
        ValueEntry."LSC Valued Quantity" := ItemLedgerEntry.Quantity;
        ValueEntry."Location Code" := ItemLedgerEntry."Location Code";
        ValueEntry."LSC Location Code" := ItemLedgerEntry."Location Code";
        ValueEntry."Posting Date" := ItemLedgerEntry."Posting Date";
        ValueEntry."LSC Posting Date" := ItemLedgerEntry."Posting Date";
        ValueEntry."VAT Reporting Date" := ItemLedgerEntry."Posting Date";
        ValueEntry."Valuation Date" := ItemLedgerEntry."Posting Date";
        ValueEntry."Item Ledger Entry Type" := ItemLedgerEntry."Entry Type";
        ValueEntry."LSC Item Ledger Entry Type" := ItemLedgerEntry."Entry Type".AsInteger();
        ValueEntry."Source Type" := ItemLedgerEntry."Source Type";
        ValueEntry."Source No." := ItemLedgerEntry."Source No.";
        ValueEntry."Source Code" := F14;
        ValueEntry."Source Posting Group" := F15;
        ValueEntry."Document No." := ItemLedgerEntry."Document No.";
        ValueEntry."Invoiced Quantity" := ItemLedgerEntry."Invoiced Quantity";
        ValueEntry."LSC Invoiced Quantity" := ItemLedgerEntry."Invoiced Quantity";
        ValueEntry."Applies-to Entry" := ItemLedgerEntry."Applies-to Entry";
        ValueEntry."Dimension Set ID" := ItemLedgerEntry."Dimension Set ID";
        ValueEntry."Global Dimension 1 Code" := ItemLedgerEntry."Global Dimension 1 Code";
        ValueEntry."LSC Global Dimension 1 Code" := ItemLedgerEntry."Global Dimension 1 Code";
        ValueEntry."Global Dimension 2 Code" := ItemLedgerEntry."Global Dimension 2 Code";
        ValueEntry."LSC Global Dimension 2 Code" := ItemLedgerEntry."Global Dimension 2 Code";
        ValueEntry."Document Date" := ItemLedgerEntry."Document Date";
        ValueEntry."External Document No." := ItemLedgerEntry."External Document No.";
        ValueEntry."Document Type" := ItemLedgerEntry."Document Type";
        ValueEntry."Document Line No." := ItemLedgerEntry."Document Line No.";
        ValueEntry."Order Type" := ItemLedgerEntry."Order Type";
        ValueEntry."Order No." := ItemLedgerEntry."Order No.";
        ValueEntry."Order Line No." := ItemLedgerEntry."Order Line No.";
        ValueEntry."Job No." := ItemLedgerEntry."Job No.";
        ValueEntry."Job Task No." := ItemLedgerEntry."Job Task No.";
        Evaluate(ValueEntry."Job Ledger Entry No.", F42);
        ValueEntry."Variant Code" := ItemLedgerEntry."Variant Code";
        ValueEntry."LSC Variant Code" := ItemLedgerEntry."Variant Code";
        ValueEntry."LSC Division" := F45;
        ValueEntry."LSC Item Category" := ItemLedgerEntry."Item Category Code";
        ValueEntry."LSC Retail Product Code" := ItemLedgerEntry."LSC Retail Product Code";
        ValueEntry."Return Reason Code" := ItemLedgerEntry."Return Reason Code";
        ValueEntry."User ID" := ItemLedgerEntry."BPC.User ID";
        ValueEntry."LSC Offer No." := ItemLedgerEntry."LSC Offer No.";
        ValueEntry."LSC Batch No." := ItemLedgerEntry."LSC Batch No.";
        ValueEntry."Journal Batch Name" := F62;
        ValueEntry."LSC Promotion No." := ItemLedgerEntry."LSC Promotion No.";
        ValueEntry."Reason Code" := F66;
        ValueEntry."Inventory Posting Group" := F67;
        ValueEntry."Gen. Bus. Posting Group" := F68;
        ValueEntry."Gen. Prod. Posting Group" := F69;
        Evaluate(ValueEntry.Inventoriable, F70);
        Evaluate(ValueEntry.Type, F71);
        Evaluate(ValueEntry."Discount Amount", F72);
        Evaluate(ValueEntry."LSC Discount Amount", F72);
        ValueEntry."Salespers./Purch. Code" := F73;
        ValueEntry."LSC Salespers./Purch. Code" := F73;
        ValueEntry."LSC Vendor No." := F74;
        Evaluate(ValueEntry."Expected Cost", F75);
        Evaluate(ValueEntry."Cost Amount (Actual)", F76);
        Evaluate(ValueEntry."LSC Cost Amount (Actual)", F76);
        Evaluate(ValueEntry."Sales Amount (Actual)", F79);
        Evaluate(ValueEntry."LSC Sales Amount (Actual)", F79);
        Evaluate(ValueEntry."Sales Amount (Expected)", F80);
        Evaluate(ValueEntry."Purchase Amount (Actual)", F81);
        Evaluate(ValueEntry."Purchase Amount (Expected)", F82);
        Evaluate(ValueEntry."Cost per Unit (ACY)", F83);
        Evaluate(ValueEntry."Cost Amount (Actual) (ACY)", F84);
        Evaluate(ValueEntry."Cost Amount (Expected) (ACY)", F85);
        Evaluate(ValueEntry."Cost Amount (Non-Invtbl.)(ACY)", F86);
        VEEntryNo += 1;
        ValueEntry."Entry No." := VEEntryNo;
        ValueEntry.Insert();
    end;
}
//Kim 2025-03 --
#endregion