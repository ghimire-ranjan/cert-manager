// Which protocols each service is served over. All in one place.
//   @odata : the Fiori apps (and any OData client)
//   @mcp   : AI assistants call the service as tools (describe, query, call), at /mcp/...
//   @agent : the service is also an AI agent other agents can talk to (A2A), at /a2a/...
// Listing a protocol replaces the default (OData only), so always keep @odata here.

using {CertService} from './cert-service';
using {AdminService} from './admin-service';

annotate CertService with @agent @mcp @odata;

// Admin only: @requires: 'admin' on AdminService applies to all three protocols
annotate AdminService with @agent @mcp @odata;
