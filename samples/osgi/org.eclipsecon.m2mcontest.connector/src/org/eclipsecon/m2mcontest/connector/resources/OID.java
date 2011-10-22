package org.eclipsecon.m2mcontest.connector.resources;

import javax.xml.bind.annotation.XmlElement;
import javax.xml.bind.annotation.XmlRootElement;

@XmlRootElement
public class OID {
	@XmlElement(name = "$oid")
	public String oid;

	public OID() {
	}
}
