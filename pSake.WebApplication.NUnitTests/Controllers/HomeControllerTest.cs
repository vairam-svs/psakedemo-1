using System.Web.Mvc;
using NUnit.Framework;
using pSake.WebApplication.Controllers;

namespace pSake.WebApplication.NUnitTests.Controllers
{
    [TestFixture]
    public class HomeControllerTest
    {
        [Test]
        public void Index()
        {
            // Arrange
            var controller = new HomeController();

            // Act
            var result = controller.Index() as ViewResult;

            // Assert
            Assert.IsNotNull(result);
        }

    }
}