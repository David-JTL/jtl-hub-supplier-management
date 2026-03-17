var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new() { Title = "JTL Supplier Management API", Version = "v1" });
});

var app = builder.Build();

app.UseSwagger();
app.UseSwaggerUI();

// Static Files (React Frontend aus wwwroot)
app.UseDefaultFiles();
app.UseStaticFiles();

app.MapControllers();

// SPA Fallback: Alle nicht-API-Routen auf index.html
app.MapFallbackToFile("index.html");

app.Run();
