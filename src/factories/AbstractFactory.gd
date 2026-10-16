class_name AbstractFactory
extends AbstractMapLoader
## Port of factories.AbstractFactory. The subclasses are designed as
## singletons. Banks are read from Values.Banks.


## Java: protected void parseFile(String filename) -> parseFile(Values.Banks, filename).
## When filename is "" the single Java argument (the file name) is in path.
func parseFile(path: String, filename: String = ""):
	if filename == "":
		super.parseFile(Values.Banks, path)
	else:
		super.parseFile(path, filename)
