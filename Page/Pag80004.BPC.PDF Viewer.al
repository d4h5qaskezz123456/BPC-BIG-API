page 80004 "BPC.PDF Viewer"
{
    Caption = 'PDF Viewer';
    PageType = Card;
    UsageCategory = None;
    SourceTable = "Sales Shipment Header";
    layout
    {
        area(content)
        {

            group(General)
            {
                ShowCaption = false;
                usercontrol(PDFViewer; "PDFV PDF Viewer")
                {
                    ApplicationArea = All;

                    trigger ControlAddinReady()
                    var
                        FileManagement: Codeunit "File Management";
                        TempBlob: Codeunit "Temp Blob";
                        OutStream: OutStream;
                        name: Text;
                        InStream: InStream;
                        TenantMedia: Record "Tenant Media";
                    begin
                        if TenantMedia.Get(Rec."BPC.File PDF".Item(1)) then begin
                            TenantMedia.CalcFields(Content);
                            if TenantMedia.Content.HasValue then begin
                                name := StrSubstNo('%1.pdf', rec."Order No.");
                                TenantMedia.Content.CreateInStream(InStream);
                                SetPDFDocument(InStream);
                                //DownloadFromStream(InStream, 'Download', '', '*.pdf', name);

                            end;
                        end;

                    end;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(DownloadPDF)
            {
                Caption = 'Download PDF';
                ApplicationArea = all;
                Image = Download;
                Promoted = true;
                PromotedCategory = Process;
                trigger OnAction()
                var
                    FileManagement: Codeunit "File Management";
                    TempBlob: Codeunit "Temp Blob";
                    OutStream: OutStream;
                    name: Text;
                    InStream: InStream;
                    TenantMedia: Record "Tenant Media";
                begin
                    if TenantMedia.Get(Rec."BPC.File PDF".Item(1)) then begin
                        TenantMedia.CalcFields(Content);
                        if TenantMedia.Content.HasValue then begin
                            name := StrSubstNo('%1.pdf', rec."Order No.");
                            //name := StrSubstNo('%1.txt', rec."Order No.");
                            TenantMedia.Content.CreateInStream(InStream);
                            DownloadFromStream(InStream, 'Download', '', '*.pdf', name);
                            //DownloadFromStream(InStream, 'Download', '', '*.txt', name);

                        end;
                    end;
                end;
            }
        }
    }
    procedure SetPDFDocument(PDFInStream: InStream)
    var
        Base64Convert: Codeunit "Base64 Convert";
    begin
        PDFAsTxt := Base64Convert.ToBase64(PDFInStream);

        CurrPage.PDFViewer.LoadPDF(PDFAsTxt, false);
    end;

    var
        PDFAsTxt: Text;
        PDFAliasLbl: Label 'data:application/pdf;base64,', Locked = true;
}