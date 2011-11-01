/*******************************************************************************
 * Copyright (c) 2011 Sierra Wireless All rights reserved. This program and the
 * accompanying materials are made available under the terms of the Eclipse
 * Public License v1.0 which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors: Benjamin Cabé (Sierra Wireless) - initial API and
 * implementation
 *******************************************************************************/
import com.mongodb.BasicDBObject;

@SuppressWarnings("serial")
public class RFIDInfo extends BasicDBObject {
	private static final String RFID_TAG = "tag";
	private static final String RFID_TYPE = "type";
	private static final String RFID_DESCRIPTION = "description";
	private static final String RFID_IMAGE = "imageURL";
	private static final String RFID_BARCODE = "barcode";

	public RFIDInfo(String tag, String type, String desc, String imgUrl,
			String barcode) {
		this.put(RFID_TAG, tag);
		this.put(RFID_TYPE, type);
		this.put(RFID_DESCRIPTION, desc);
		this.put(RFID_IMAGE, imgUrl);
		this.put(RFID_BARCODE, barcode);
	}

	@Override
	public String toString() {
		return "RFIDInfo: \"" + this.get(RFID_TAG) + "\" "
				+ this.get(RFID_TYPE) + "\" " + this.get(RFID_DESCRIPTION)
				+ "\" " + this.get(RFID_IMAGE) + "\" " + this.get(RFID_BARCODE);
	}

}
