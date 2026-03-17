using Microsoft.AspNetCore.Mvc;

namespace SupplierManagement.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class HealthController : ControllerBase
{
    [HttpGet]
    public IActionResult Get()
    {
        return Ok(new
        {
            Status = "Healthy",
            Service = "SupplierManagement.Api",
            Version = "1.0.0",
            Timestamp = DateTime.UtcNow
        });
    }
}
