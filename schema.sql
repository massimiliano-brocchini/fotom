CREATE TABLE IF NOT EXISTS foto (
	id INTEGER PRIMARY KEY ASC,
	image_unique_id NOT NULL,
	path NOT NULL,
	orientation,
	deleted NOT NULL DEFAULT 'N',
	UNIQUE (image_unique_id),
	UNIQUE (path)
);

CREATE TABLE IF NOT EXISTS video (
	id INTEGER PRIMARY KEY ASC,
	original_md5 NOT NULL,
	imported_md5 NOT NULL,
	path NOT NULL,
	deleted NOT NULL DEFAULT 'N',
	UNIQUE (path),
	UNIQUE (original_md5),
	UNIQUE (imported_md5)
);

CREATE TABLE IF NOT EXISTS just_imported (
	foto_id INTEGER,
	video_id INTEGER
);

CREATE TABLE IF NOT EXISTS tags (
	id INTEGER PRIMARY KEY ASC,
	tag NOT NULL,
	UNIQUE (tag)
);

CREATE TABLE IF NOT EXISTS foto_tags (
	foto_id INTEGER NOT NULL,
	tag_id INTEGER NOT NULL,
	UNIQUE (foto_id,tag_id),
	FOREIGN KEY(foto_id) REFERENCES foto(id) ON DELETE CASCADE,
	FOREIGN KEY(tag_id)  REFERENCES tags(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS video_tags (
	video_id INTEGER NOT NULL,
	tag_id INTEGER NOT NULL,
	UNIQUE (video_id,tag_id),
	FOREIGN KEY(video_id) REFERENCES video(id) ON DELETE CASCADE,
	FOREIGN KEY(tag_id)   REFERENCES tags(id)  ON DELETE CASCADE
);
