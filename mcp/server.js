// MCP server for cert-manager: read-only tools that call the app's OData API
// as one logged-in user, so the app's own rules (@restrict) decide what they see.
const { McpServer } = require("@modelcontextprotocol/sdk/server/mcp.js");
const { StdioServerTransport } = require("@modelcontextprotocol/sdk/server/stdio.js");
const { z } = require("zod");

const API = process.env.CERT_API || "http://localhost:4004/odata/v4/cert";
const USER = process.env.CERT_USER;
const PASSWORD = process.env.CERT_PASSWORD;
const AUTH = "Basic " + Buffer.from(`${USER}:${PASSWORD}`).toString("base64");

// GET one OData path and return its rows; throw the app's error message on failure
async function get(path) {
  const res = await fetch(`${API}/${path}`, {
    headers: { Authorization: AUTH, Accept: "application/json" },
  });
  const body = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(body.error?.message || `HTTP ${res.status}`);
  return body.value ?? body;
}

// Today + days, as 'YYYY-MM-DD' in local time
function dateInDays(days) {
  const d = new Date();
  d.setDate(d.getDate() + days);
  const m = String(d.getMonth() + 1).padStart(2, "0");
  return `${d.getFullYear()}-${m}-${String(d.getDate()).padStart(2, "0")}`;
}

// Wrap a tool so errors come back as a readable tool error, not a crash
function asText(fn) {
  return async (args) => {
    try {
      return { content: [{ type: "text", text: JSON.stringify(await fn(args), null, 2) }] };
    } catch (e) {
      return { isError: true, content: [{ type: "text", text: e.message }] };
    }
  };
}

const server = new McpServer({ name: "cert-manager", version: "0.1.0" });

server.registerTool(
  "who_am_i",
  {
    title: "Who am I",
    description: "The employee this assistant is logged in as (name, login, manager).",
  },
  asText(async () => {
    const rows = await get(
      `Employees?$filter=${encodeURIComponent(`userID eq '${USER}'`)}` +
        `&$select=name,userID,email,active&$expand=manager($select=name)`,
    );
    return rows[0] ?? { userID: USER, note: "No employee record for this login" };
  }),
);

server.registerTool(
  "list_certifications",
  {
    title: "List certifications",
    description:
      "Certification records the user may see: employees see their own, managers also " +
      "their team's, admins everyone's. Each row has the certification, employee, status, " +
      "valid-until date and days left (negative = expired).",
    inputSchema: {
      expiringWithinDays: z
        .number()
        .int()
        .optional()
        .describe("Only records whose validUntil is within this many days from today (expired ones included)"),
      status: z
        .enum(["Planned", "LearningJourney", "Pending", "Verified", "Rejected"])
        .optional()
        .describe("Only records with this status"),
      employeeName: z.string().optional().describe("Only employees whose name contains this text"),
    },
  },
  asText(async ({ expiringWithinDays, status, employeeName }) => {
    const filters = ["IsActiveEntity eq true"];
    if (expiringWithinDays !== undefined) filters.push(`validUntil le ${dateInDays(expiringWithinDays)}`);
    if (status) filters.push(`status_code eq '${status}'`);
    if (employeeName) filters.push(`contains(employee/name,'${employeeName.replace(/'/g, "''")}')`);
    const rows = await get(
      `EmployeeCertifications?$filter=${encodeURIComponent(filters.join(" and "))}` +
        `&$select=status_code,earnedOn,plannedFor,validUntil,daysUntilExpiry` +
        `&$expand=employee($select=name),certificate($select=code,name),status($select=name)` +
        `&$orderby=validUntil`,
    );
    return rows.map((r) => ({
      employee: r.employee?.name,
      code: r.certificate?.code,
      certification: r.certificate?.name,
      status: r.status?.name ?? r.status_code,
      earnedOn: r.earnedOn,
      plannedFor: r.plannedFor,
      validUntil: r.validUntil,
      daysLeft: r.daysUntilExpiry,
    }));
  }),
);

server.registerTool(
  "list_catalogue",
  {
    title: "List the certification catalogue",
    description: "All certifications that exist in the catalogue (code, name, issuer).",
  },
  asText(() => get("Certifications?$select=code,name,issuer&$orderby=code")),
);

server.connect(new StdioServerTransport());
