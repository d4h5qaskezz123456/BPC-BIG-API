pageextension 80022 "BPC.Posted Purchase Invoice" extends "Posted Purchase Invoice"
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        addlast(processing)
        {
            action("Resend to D365")
            {
                Caption = 'Resend to D365';
                Promoted = true;
                PromotedCategory = Process;
                ApplicationArea = Basic, Suite;
                trigger OnAction()
                var
                    RetailSetup: Record "LSC Retail Setup";
                    InterfaceData: Codeunit "BPC.Interface Data";
                    ErrText: Text;
                begin

                    RetailSetup.Get();
                    if (RetailSetup."BPC.Interface D365 Active") then
                        InterfaceData.SendExpense(rec, Rec."No.", FALSE, ErrText);
                end;

            }
        }
    }

    procedure WriteAsText(Content: Text; Encoding: TextEncoding)
    var
        OutStr: OutStream;
        //Blob: Record "BPC.Blob";
        Blob: Codeunit "Temp Blob";
    begin
        CLEAR(Blob);
        IF Content = '' THEN
            EXIT;
        Blob.CREATEOUTSTREAM(OutStr, Encoding);
        OutStr.WRITETEXT(Content);
    end;

    procedure ReadAsText(LineSeparator: Text; Encoding: TextEncoding) Content: Text
    var
        InStream: InStream;
        ContentLine: Text;
        //Blob: Record "BPC.Blob";
        Blob: Codeunit "Temp Blob";
    begin
        Blob.CREATEINSTREAM(InStream, Encoding);
        InStream.READTEXT(Content);
        WHILE NOT InStream.EOS DO BEGIN
            InStream.READTEXT(ContentLine);
            Content += LineSeparator + ContentLine;
        END;
    end;
    // procedure ConvertBase64toPDF(VAR RecpostedSalesInvoice: Record "Sales Invoice Header")
    // var
    //     CUBase64Convert: Codeunit "Base64 Convert";
    //     CUtempBlob: Codeunit "Temp Blob";
    //     TempOStream: OutStream;
    //     TempInstream: InStream;
    //     recref: RecordRef;
    //     RecDocAttached: Record "Document Attachment";
    //     FileName: text;
    //     InvoiceData: Record "EInvoice Data"; //this is my custom table with Blob value
    // begin
    //     IF invoiceData.Get(RecpostedSalesInvoice."No.") then BEGIN
    //         invoiceData.CalcFields(invoiceData.Blob);
    //         if InvoiceData.Blob.HasValue then begin
    //             CUTempBlob.CreateOutStream(TempOStream);
    //             CUTempBlob.FromRecord(invoiceData, invoiceData.FieldNo(Blob));
    //             CUtempBlob.CreateInStream(TempInstream);
    //             RecRef.GetTable(RecpostedSalesInvoice);
    //             FileName := StrSubstNo('E-Invoice_%1.PDF', RecpostedSalesInvoice."No.");
    //             if FileName <> '' then
    //                 RecDocAttached.SaveAttachmentFromStream(TempinStream, RecRef, FileName);
    //         end;
    //     end;
    // end;

    var
}