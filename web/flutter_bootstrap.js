{{flutter_js}}
{{flutter_build_config}}

const searchParams = new URLSearchParams(window.location.search);
const renderer = searchParams.get('renderer');
const userConfig = renderer ? {renderer} : {};

function reportMasarFlutterLoadError(error) {
  window.dispatchEvent(
    new CustomEvent('masar-flutter-load-error', {
      detail: {
        message: error && error.message ? error.message : String(error),
      },
    }),
  );
}

_flutter.loader
  .load({
    config: userConfig,
    onEntrypointLoaded: async function (engineInitializer) {
      try {
        const appRunner = await engineInitializer.initializeEngine();
        await appRunner.runApp();
      } catch (error) {
        reportMasarFlutterLoadError(error);
        throw error;
      }
    },
  })
  .catch(function (error) {
    reportMasarFlutterLoadError(error);
    throw error;
  });
