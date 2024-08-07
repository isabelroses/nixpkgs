{
  lib,
  buildPythonPackage,
  dnspython,
  fetchPypi,
  geoip2,
  ipython,
  isPyPy,
  praw,
  pyenchant,
  pygeoip,
  pytestCheckHook,
  pythonOlder,
  pytz,
  sqlalchemy,
  xmltodict,
}:

buildPythonPackage rec {
  pname = "sopel";
  version = "8.0.0";
  format = "setuptools";

  disabled = isPyPy || pythonOlder "3.7";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-juLJp0Et5qMZwBZzw0e4tKg1cBYqAsH8KUzqNoIP70U=";
  };

  patches = [
    # https://github.com/sopel-irc/sopel/issues/2401
    # https://github.com/sopel-irc/sopel/commit/596adc44330939519784389cbb927435305ef758.patch
    # rewrite the patch because there are too many patches needed to apply the above patch.
    ./python311-support.patch
  ];

  propagatedBuildInputs = [
    dnspython
    geoip2
    ipython
    praw
    pyenchant
    pygeoip
    pytz
    sqlalchemy
    xmltodict
  ];

  nativeCheckInputs = [ pytestCheckHook ];

  postPatch = ''
    substituteInPlace requirements.txt \
      --replace "praw>=4.0.0,<6.0.0" "praw" \
      --replace "sqlalchemy<1.4" "sqlalchemy" \
      --replace "xmltodict==0.12" "xmltodict>=0.12"
  '';

  preCheck = ''
    export TESTDIR=$(mktemp -d)
    cp -R ./test $TESTDIR
    pushd $TESTDIR
  '';

  postCheck = ''
    popd
  '';

  pythonImportsCheck = [ "sopel" ];

  meta = with lib; {
    description = "Simple and extensible IRC bot";
    homepage = "https://sopel.chat";
    license = licenses.efl20;
    maintainers = with maintainers; [ mog ];
  };
}
