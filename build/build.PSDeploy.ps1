Deploy Module {
    By PSGalleryModule {
        Tagged Release
        FromSource $BuildFolder
        To PSGallery
        WithOptions @{
            ApiKey = $ENV:NugetApiKey
        }
    }
}
