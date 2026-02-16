using System.IO;
using System.Threading.Tasks;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Processing;

namespace ImageProcessor
{
    public class ResizeImage
    {
        private readonly ILogger _logger;

        public ResizeImage(ILoggerFactory loggerFactory)
        {
            _logger = loggerFactory.CreateLogger<ResizeImage>();
        }

        [Function(nameof(ResizeImage))]
        // Output: Här sparas den färdiga bilden i "thumbnails"
        [BlobOutput("thumbnails/{name}", Connection = "AzureWebJobsStorage")]
        public async Task<byte[]> Run(
            // Trigger: Funktionen startar när en bild landar i "upload"
            [BlobTrigger("upload/{name}", Connection = "AzureWebJobsStorage")] byte[] myBlob,
            string name)
        {
            _logger.LogInformation($"Processing image: {name}");

            // Vi öppnar bilden från de bytes vi fick in
            using var image = Image.Load(myBlob);

            // Här ändrar vi storleken. Vi gör den 200 pixlar bred 
            // och låter biblioteket räkna ut höjden automatiskt (propertionerligt)
            image.Mutate(x => x.Resize(new ResizeOptions
            {
                Size = new Size(200, 0),
                Mode = ResizeMode.Max
            }));

            // Vi sparar ner den modifierade bilden till en "slang" (MemoryStream)
            using var ms = new MemoryStream();
            await image.SaveAsJpegAsync(ms);

            _logger.LogInformation($"Image {name} resized successfully.");

            // Vi skickar tillbaka resultatet som en byte-array till Azure Storage
            return ms.ToArray();
        }
    }
}