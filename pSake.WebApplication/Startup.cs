using Microsoft.Owin;
using Owin;

[assembly: OwinStartupAttribute(typeof(pSake.WebApplication.Startup))]
namespace pSake.WebApplication
{
    public partial class Startup
    {
        public void Configuration(IAppBuilder app)
        {
            ConfigureAuth(app);
        }
    }
}
