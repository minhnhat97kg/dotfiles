{ lib
, python3
, fetchPypi
}:

python3.pkgs.buildPythonApplication rec {
  pname = "stormssh";
  version = "0.7.0";
  format = "setuptools";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # Will fix in next step
  };

  propagatedBuildInputs = with python3.pkgs; [
    paramiko
    termcolor
    six
  ];

  # Storm has no tests in the package
  doCheck = false;

  meta = with lib; {
    description = "Manage your SSH like a boss";
    homepage = "https://github.com/emre/storm";
    license = licenses.mit;
    maintainers = [ ];
  };
}
