{
  description = "A collection of useful overlays";

  outputs = { self, ... }: {
    overlays = {
      pandas = final: prev: {
        python3 = prev.python3.override {
          packageOverrides = python-final: python-prev: {
            pandas = python-prev.pandas.overrideAttrs (attrs: rec {
              pname = "pandas";
              version = "1.3.4";

              src = python-prev.fetchPypi {
                inherit pname version;
                sha256 = "1z3gm521wpm3j13rwhlb4f2x0645zvxkgxij37i3imdpy39iiam2";
              };
            });
          };
        };
      };
      mlflow = final: prev: {
        python3 = prev.python3.override {
          packageOverrides = python-final: python-prev: {
            sqlalchemy = python-prev.sqlalchemy.overrideAttrs (attrs: rec {
              pname = "SQLAlchemy";
              version = "1.3.13";
              src = python-prev.fetchPypi {
                inherit pname version;
                sha256 =
                  "sha256:1yxlswgb3h15ra8849vx2a4kp80jza9hk0lngs026r6v8qcbg9v4";
              };
              doInstallCheck = false;
            });
            alembic = python-prev.alembic.overrideAttrs (attrs: rec {
              pname = "alembic";
              version = "1.4.1";
              src = python-prev.fetchPypi {
                inherit pname version;
                sha256 =
                  "sha256:0a4hzn76csgbf1px4f5vfm256byvjrqkgi9869nkcjrwjn35c6kr";
              };
              propagatedBuildInputs = with python-prev; [
                python-editor
                python-dateutil
                python-final.sqlalchemy
                Mako
              ];
              doInstallCheck = false;
            });
            mlflow = (python-prev.mlflow.override {
              sqlalchemy = python-final.sqlalchemy;
              alembic = python-final.alembic;
            }).overrideAttrs (attrs: {
              propagatedBuildInputs = attrs.propagatedBuildInputs
                ++ (with python-final; [
                  importlib-metadata
                  prometheus-flask-exporter
                  azure-storage-blob
                ]);
              meta.broken = false;
            });
          };
        };
      };
    };
  };
}
