pageextension 80013 "BPC.Posted Sales Shipment" extends "Posted Sales Shipment"
{
    layout
    {
        // Add changes to page layout here
    }
    actions
    {
        addafter("&Print")
        {
            action(ReSendPostSalesShipment)
            {
                ApplicationArea = Location;
                Caption = 'Re-Sent SO Ship to 365';
                Image = Action;
                Promoted = true;
                PromotedCategory = Process;
                trigger OnAction()
                var
                    ErrText: Text;
                begin
                    RetailSetup.Get();
                    if Confirm('Re-Sent SO Ship to 365 ?', true, Rec."No.") then begin
                        RetailSetup.TestField("bpc.Interface D365 Active");
                        SalesShipmentHeader.Reset();
                        SalesShipmentHeader.SetRange("No.", rec."No.");
                        if SalesShipmentHeader.FindSet() then
                            ReSendInterface.ReSendPostSalesShipment(SalesShipmentHeader)
                    end;
                end;


            }

            // action(Test)
            // {
            //     Caption = 'test';
            //     Promoted = true;
            //     PromotedCategory = Process;
            //     trigger OnAction()
            //     var
            //         Base64: Codeunit "Base64 Convert";
            //         text: Text;
            //         InStream: InStream;
            //         textdd: Text;
            //         CUtempBlob: Codeunit "Temp Blob";
            //         TempOStream: OutStream;
            //         name: Text;
            //         f: TextEncoding;
            //         PersistentBlob: Codeunit "Persistent Blob";
            //         Blob: Record "BPC.Blob" temporary;
            //     begin

            //         text := '';

            //         // if rec."BPC.File PDF".Remove(mediasetId) then
            //         //     rec.Modify();
            //         CUTempBlob.CreateOutStream(TempOStream);
            //         Base64.FromBase64(text, TempOStream);
            //         TempOStream.WriteText(textdd);
            //         CUTempBlob.CreateInStream(InStream);
            //         name := StrSubstNo('%1.pdf', rec."Order No.");
            //         //DownloadFromStream(InStream, 'Download', '', '*.txt', name);
            //         if DownloadFromStream(InStream, 'Download', '', '*.pdf', name) then begin
            //             rec."BPC.File PDF".IMPORTSTREAM(InStream, name);
            //             rec.Modify();
            //         end;
            //         // SalesShipmentHeader.Reset();
            //         // SalesShipmentHeader.SetRange("Order No.", Rec."No.");
            //         // if SalesShipmentHeader.FindSet() then begin
            //         // end;

            //     end;
            // }
            action(PDFViewer)
            {
                Caption = 'Preview PDF';
                Promoted = true;
                PromotedCategory = Process;
                ApplicationArea = all;
                Image = View;
                trigger OnAction()
                var
                    FileManagement: Codeunit "File Management";
                    TempBlob: Codeunit "Temp Blob";
                    OutStream: OutStream;
                    name: Text;
                    InStream: InStream;
                    TenantMedia: Record "Tenant Media";
                begin
                    Page.Run(Page::"BPC.PDF Viewer", Rec);
                end;
            }
            // action(tt)
            // {
            //     Caption = 'ลบ';
            //     Promoted = true;
            //     PromotedCategory = Process;
            //     ApplicationArea = all;
            //     Image = View;
            //     trigger OnAction()
            //     var
            //         FileManagement: Codeunit "File Management";
            //         TempBlob: Codeunit "Temp Blob";
            //         OutStream: OutStream;
            //         name: Text;
            //         InStream: InStream;
            //         TenantMedia: Record "Tenant Media";
            //         mediasetId: GUID;
            //         tt: Codeunit "BPC.QtySoldNotPost";
            //     begin
            //         tt.Run(rec);
            //         CurrPage.Update();
            //     end;
            // }

        }
    }
    local procedure MyProcedure()
    var
        myInt: Integer;
    begin
    end;

    var



        SalesShipmentHeader: Record "Sales Shipment Header";
        ReSendInterface: Codeunit "BPC.ReSend Interface";
        RetailSetup: Record "LSC Retail Setup";

}