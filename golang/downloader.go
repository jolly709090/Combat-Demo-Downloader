package main

import (
	"compress/gzip"
	"crypto/sha1"
	"encoding/xml"
	"fmt"
	"io"
	"io/ioutil"
	"math"
	"net/http"
	"os"
	"path/filepath"
	"strings"
)

type Manifest struct {
	XMLName xml.Name `xml:"Manifest:`
	File    []File   `xml:"File"`
}

type File struct {
	Path     string `xml:"Path"`
	Hash     string `xml:"Hash"`
	Size     int    `xml:"Size"`
	Download string `xml:"Download"`
}

func main() {
	url := "http://cdn.zaonce.net/elitedangerous/win/manifests/Single+Player+Combat+Training+%282014.11.26.51787%29.xml.gz"
	resp, _ := http.Get(url)
	defer resp.Body.Close()
	reader, _ := gzip.NewReader(resp.Body)
	ungz, _ := ioutil.ReadAll(reader)

	manifest := &Manifest{}
	xml.Unmarshal(ungz, manifest)

	dir := "./COMBAT_TUTORIAL_DEMO/"
	sourceinfo, _ := os.Stat(".")

	for i := 0; i < len(manifest.File); i++ {
		mypath := filepath.FromSlash(strings.Replace(dir+manifest.File[i].Path, "\\", "/", -1))
		file, _ := os.Open(mypath)
		download := func() {
			dir := filepath.Dir(mypath)
			os.MkdirAll(dir, sourceinfo.Mode())
			out, _ := os.Create(mypath)
			fmt.Println("Downloading " + mypath)
			resp, _ := http.Get(manifest.File[i].Download)
			defer resp.Body.Close()
			io.Copy(out, resp.Body)
		}
		if file == nil {
			download()
		} else {
			hash := getSha1(file)
			defer file.Close()
			if hash == manifest.File[i].Hash {
				fmt.Println("Skipping " + file.Name())
			} else {
				download()
			}
		}
	}

}

func getSha1(file *os.File) (result string) {
	const filechunk = 8192 // we settle for 8KB
	info, _ := file.Stat()
	filesize := info.Size()
	blocks := uint64(math.Ceil(float64(filesize) / float64(filechunk)))
	hash := sha1.New()
	for i := uint64(0); i < blocks; i++ {
		blocksize := int(math.Min(filechunk, float64(filesize-int64(i*filechunk))))
		buf := make([]byte, blocksize)
		file.Read(buf)
		io.WriteString(hash, string(buf)) // append into the hash
	}

	return strings.TrimSpace(fmt.Sprintf("%x\n", hash.Sum(nil)))
}
