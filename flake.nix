{
  description = "A collection of useful flakes";

  outputs = { self, ... }: rec {
    # https://github.com/NixOS/nixpkgs/issues/44426
    # https://discourse.nixos.org/t/makeextensibleasoverlay/7116/5
    pythonPackageOverlay = attr: overlay: self: super: {
      ${attr} = self.lib.fix (py:
        super.${attr}.override (old: {
          self = py;
          packageOverrides =
            self.lib.composeExtensions (old.packageOverrides or (_: _: { }))
            overlay;
        }));
    };
    overlays = {
      pandas134 = pythonPackageOverlay "python39" (final: prev: {
        pandas = prev.pandas.overridePythonAttrs (attrs: rec {
          pname = "pandas";
          version = "1.3.4";

          src = prev.fetchPypi {
            inherit pname version;
            sha256 = "1z3gm521wpm3j13rwhlb4f2x0645zvxkgxij37i3imdpy39iiam2";
          };
        });
      });
      mlflow = pythonPackageOverlay "python39" (final: prev: {
        sqlalchemy = prev.sqlalchemy.overridePythonAttrs (attrs: rec {
          pname = "SQLAlchemy";
          # Version 1.3.13 seems to be incompatible with Python 3.9.
          # version = "1.3.13";
          version = "1.4.0";
          src = prev.fetchPypi {
            inherit pname version;
            sha256 = "sha256-nP7yrTDF7h1JTZjzxVqawp7G0pS3CEnFQdE55P4adOY=";
          };
          doInstallCheck = false;
          doCheck = false;
        });
        alembic = prev.alembic.overridePythonAttrs (attrs: rec {
          pname = "alembic";
          version = "1.4.1";
          src = prev.fetchPypi {
            inherit pname version;
            sha256 =
              "sha256:0a4hzn76csgbf1px4f5vfm256byvjrqkgi9869nkcjrwjn35c6kr";
          };
          # Something is broken in the alembic tests (probably has to do with
          # some incompatibility with the SQLAlchemy version):
          # AttributeError: 'PytestFixtureFunctions' object has no attribute
          # 'mark_base_test_class'.
          doCheck = false;
          propagatedBuildInputs = with prev; [
            python-editor
            python-dateutil
            final.sqlalchemy
            Mako
          ];
          doInstallCheck = false;
        });
        mlflow = (prev.mlflow.override {
          sqlalchemy = final.sqlalchemy;
          alembic = final.alembic;
          pandas = final.pandas;
        }).overridePythonAttrs (attrs: rec {
          pname = "mlflow";
          version = "1.22.0";
          src = prev.fetchPypi {
            inherit pname version;
            sha256 = "sha256-9oA5BxXkNq44z3BW7JEDD8nrZ8xjEibyj/lQT745Wt0=";
          };
          propagatedBuildInputs = attrs.propagatedBuildInputs ++ (with final; [
            importlib-metadata
            prometheus-flask-exporter
            azure-storage-blob
          ]);
          meta.broken = false;
        });
      });
    };
    khal = (final: prev:
      (let
        tzlocal21 = prev.python39.pkgs.tzlocal.overridePythonAttrs (attrs: rec {
          pname = "tzlocal";
          version = "2.1";

          propagatedBuildInputs = [ prev.python39.pkgs.pytz ];

          doCheck = false;

          pythonImportsCheck = [ "tzlocal" ];

          src = prev.python39.pkgs.fetchPypi {
            inherit pname version;
            sha256 = "sha256-ZDyXxSlK7cc3eApJ2d8wiJMhy+EgTqwsLsYTQDWpLkQ=";
          };
        });
      in {
        khal = prev.khal.overridePythonAttrs (attrs: {
          propagatedBuildInputs = (builtins.filter (i: i.pname != "tzlocal")
            attrs.propagatedBuildInputs) ++ [ tzlocal21 ];
        });
      }));
    # Yapf seems to require toml in order to work in pyproject.toml style Python
    # projects.
    yapfToml = pythonPackageOverlay "python39" (final: prev: {
      yapfToml = prev.yapf.overridePythonAttrs
        (old: rec { propagatedBuildInputs = [ prev.toml ]; });
    });
  };
}
