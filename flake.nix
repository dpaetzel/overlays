{
  description = "A collection of useful flakes";

  inputs = {
    kerasTunerSrc = {
      url = "github:keras-team/keras-tuner/1.1.0";
      flake = false;
    };

    ktLegacySrc = {
      url = "github:haifeng-jin/kt-legacy";
      flake = false;
    };
  };

  outputs = inputs@{ self, ... }: rec {

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
      mydefaults = (final: prev: {
        # Emacs is central to everything, so let's pin its version to more
        # consciously upgrade it.
        myemacs = prev.emacs29;
        # We use the default Python 3 currently used by nixpkgs (3.11.9 as
        # of 2024-06-22) because the version does really not matter much in
        # everyday use.
        mypython = prev.python3;
        # TODO Expose pythonEnv and python app?

        myjulia = prev.julia_110-bin;
      });

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
      # Yapf seems to require toml in order to work in pyproject.toml style Python
      # projects.
      yapfToml = pythonPackageOverlay "python39" (final: prev: {
        yapfToml = prev.yapf.overridePythonAttrs
          (old: rec { propagatedBuildInputs = [ prev.toml ]; });
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

    pymc4 = pythonPackageOverlay "python39" (final: prev: {
      logical-unification = prev.buildPythonPackage rec {
        pname = "logical-unification";
        version = "0.4.5";

        propagatedBuildInputs = with prev; [ multipledispatch toolz ];

        src = prev.fetchPypi {
          inherit pname version;
          sha256 = "sha256-fGpsG3xrqg9bmvk/Bs/I0kGba3kzRrZ47RNnwFznRVg=";
        };

        doCheck = false;
      };

      cons = prev.buildPythonPackage rec {
        pname = "cons";
        version = "0.4.5";

        propagatedBuildInputs = with prev; [ final.logical-unification ];

        src = prev.fetchPypi {
          inherit pname version;
          sha256 = "sha256-tGtIrbWlr39EN12jRtkm5VoyXU3BK5rdnyAoDTs3Qss=";
        };

        doCheck = false;
      };

      etuples = prev.buildPythonPackage rec {
        pname = "etuples";
        version = "0.3.4";

        propagatedBuildInputs = with prev; [ final.cons ];

        src = prev.fetchPypi {
          inherit pname version;
          sha256 = "sha256-mAUTeb0oTORi2GjkTDiaIiBrNcSVztJZBBrx8ypUoKM=";
        };

        doCheck = false;
      };

      miniKanren = prev.buildPythonPackage rec {
        pname = "miniKanren";
        version = "1.0.3";

        propagatedBuildInputs = with prev; [
          final.cons
          final.etuples
          final.logical-unification
        ];

        src = prev.fetchPypi {
          inherit pname version;
          sha256 = "sha256-Hsi9sBFErV6HUsfCl/uKEi25IPhZJ20lpy0WTpmNf24=";
        };

        doCheck = false;
      };

      aesara = prev.buildPythonPackage rec {
        pname = "aesara";
        version = "2.3.2";

        propagatedBuildInputs = with prev; [
          final.miniKanren
          final.cons

          numpy
          scipy
          filelock
        ];

        src = prev.fetchPypi {
          inherit pname version;
          sha256 = "sha256-rYk6RhVGsXR0lfsnhnZjO7jgraqLThsL3/8v6zKNFeY=";
        };

        doCheck = false;
      };

      aeppl = prev.buildPythonPackage rec {
        pname = "aeppl";
        version = "0.0.18";

        propagatedBuildInputs = with prev; [ final.aesara ];

        src = prev.fetchPypi {
          inherit pname version;
          sha256 = "sha256-I0bJhfBzEidbF7/SLoR9RAjx9hmtEZgfrrjiPS+5S7c=";
        };

        doCheck = false;
      };

      pymc4 = prev.buildPythonPackage rec {
        pname = "pymc";
        version = "4.0.0b2";

        meta.broken = false;

        src = prev.fetchPypi {
          inherit pname version;
          sha256 = "sha256-u/5kz+zFoTWPebSeaIdAR0Y8K3nV3Q04ZSwzT9/+N7Y=";
        };

        propagatedBuildInputs = with prev; [
          arviz
          cachetools
          fastprogress
          h5py
          joblib
          packaging
          pandas
          patsy
          semver
          six
          tqdm
          typing-extensions

          cloudpickle

          final.aeppl
          final.aesara
        ];

        # From the pymc3 Nix package:
        # “The test suite is computationally intensive and test failures are not
        # indicative for package usability hence tests are disabled by default.”
        doCheck = false;
        pythonImportsCheck = [ "pymc" ];

        # From the pymc3 Nix package:
        # “For some reason tests are run as a part of the *install* phase if
        # enabled.  Theano writes compiled code to ~/.theano hence we set
        # $HOME.”
        preInstall = "export HOME=$(mktemp -d)";
        postInstall = "rm -rf $HOME";

        checkInputs = with prev; [ pytest pytest-cov ];
      };
    });

    keras-tuner = pythonPackageOverlay "python38" (final: prev: rec {
      kt-legacy = prev.buildPythonPackage rec {
        pname = "kt-legacy";
        # NOTE There's no version information in the repo.
        version = "1.0";

        src = inputs.ktLegacySrc;

        doCheck = false;
      };

      keras-tuner = prev.buildPythonPackage rec {
        pname = "keras-tuner";
        version = "1.1.0";

        src = inputs.kerasTunerSrc;

        propagatedBuildInputs = with prev; [
          # From https://github.com/keras-team/keras-tuner/blob/master/setup.py.
          tensorflow-tensorboard
          packaging
          numpy
          requests
          ipython
          kt-legacy

          # Not in setup.py but required nonetheless.
          scipy
        ];

        doCheck = false;
      };
    });
  };
}
