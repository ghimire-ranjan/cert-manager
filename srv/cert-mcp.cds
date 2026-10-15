using {CertService} from './cert-service';

// Also serve CertService over MCP (at /mcp/cert), so an AI assistant can read it.
// Keep @odata: adding only @mcp would stop serving OData, and the Fiori apps need it.
annotate CertService with @mcp @odata;
