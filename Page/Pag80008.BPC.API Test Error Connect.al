page 80008 "BPC.API.Test Error ConnectSet"
{
    PageType = API;
    Caption = 'apiTestErrorConnectSet';
    APIPublisher = 'bpc';
    APIGroup = 'apiBIG';
    APIVersion = 'v2.0';
    EntityName = 'testErrorConnect';
    EntitySetName = 'testErrorConnects';
    SourceTable = "Sales Header";
    DelayedInsert = true;
    DeleteAllowed = false;
    SourceTableTemporary = true;
    ODataKeyFields = SystemId;

    layout
    {
        area(Content)
        {
            repeater(GroupConnect)
            {
                field(id; rec.SystemId)
                {
                    Caption = 'id';
                    Editable = false;
                }
                field(pTestConnect; pTestConnect)
                {
                    Caption = 'pTestConnect';
                    trigger OnValidate()
                    begin
                        pTestConnect := FuncTestConnect;
                    end;
                }
            }
        }
    }

    local procedure FuncTestConnect(): Text
    begin
        Error(STRSUBSTNO('%1 : Error Connect!', pTestConnect));
    end;

    var
        pTestConnect: Text;
}